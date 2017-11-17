defmodule Aida.Bot do
  alias Aida.{FrontDesk, Variable, Message, Skill, Logger}
  alias __MODULE__
  import Message
  @type message :: map

  @type t :: %__MODULE__{
    id: String.t,
    languages: [String.t],
    front_desk: FrontDesk.t,
    skills: [map],
    variables: [Variable.t],
    channels: []
  }

  defstruct id: nil,
            languages: [],
            front_desk: %FrontDesk{},
            skills: [],
            variables: [],
            channels: []

  @spec chat(bot :: t, message :: Message.t) :: Message.t
  def chat(%Bot{} = bot, %Message{} = message) do
    cond do
      !language(message) && Enum.count(bot.languages) == 1 ->
        message
        |> put_session("language", bot.languages |> List.first)
        |> greet(bot)
      language(message) ->
        handle(bot, message)
      true -> language_detector(bot, message)
    end
  end

  @spec greet(message :: Message.t, bot :: t) :: Message.t
  defp greet(%Message{} = message, bot) do
    message
    |> respond(bot.front_desk.greeting)
    |> introduction(bot)
  end

  @spec introduction(message :: Message.t, bot :: t) :: Message.t
  defp introduction(message, bot) do
    message = message
    |> respond(bot.front_desk.introduction)

    bot.skills
    |> Enum.reduce(message, fn(skill, message) ->
      !is_language_detector?(skill) && Skill.explain(skill, message) || message
    end)
  end

  defp clarification(message, bot, skills) do
    message = message
    |> respond(bot.front_desk.clarification)

    skills
    |> Enum.reduce(message, fn(skill, message) ->
      Skill.clarify(skill, message)
    end)
  end

  defp not_understood(message, bot) do
    message
    |> respond(bot.front_desk.not_understood)
    |> introduction(bot)
  end

  defp handle(bot, message) do
    skills = bot.skills
    |> Enum.filter(fn(skill) ->
      Skill.can_handle?(skill, message)
    end)

    case skills do
      [skill] ->
        Skill.respond(skill, message)
      [] ->
        message
        |> not_understood(bot)
      skills ->
        message
        |> clarification(bot, skills)
    end
  end

  defp language_detector(bot, message) do
    skills = bot.skills
    |> Enum.filter(fn(skill) ->
      is_language_detector?(skill)
    end)

    case skills do
      [skill] ->
        if Skill.can_handle?(skill, message) do
          Skill.respond(skill, message)
          |> greet(bot)
        else
          Skill.explain(skill, message)
        end
      _ -> Logger.info "Error: None or more than one language_detector skills were found"
    end
  end

  defp is_language_detector?(%Skill.LanguageDetector{})do
    true
  end

  defp is_language_detector?(_)do
    false
  end
end
