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

  @spec init(bot :: t) :: {:ok, t}
  def init(bot) do
    skills = bot.skills
    |> Enum.map(fn(skill) ->
      Skill.init(skill, bot)
    end)

    {:ok, %{bot | skills: skills}}
  end

  @spec wake_up(bot :: t, skill_id :: String.t) :: :ok
  def wake_up(%Bot{} = bot, skill_id) do
    find_skill(bot, skill_id)
    |> Skill.wake_up(bot)
  end

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
    skills_by_confidence = bot.skills
    |> Enum.map(fn(skill) ->
      confidence = Skill.confidence(skill, message)
      if confidence > 0 do
        %{"confidence" => confidence, "skill" => skill}
      else
        nil
      end
    end)

    skills_sorted = Enum.reject(Enum.sort_by(skills_by_confidence, fn (skill) -> skill["confidence"] end, &>=/2), &is_nil/1)

    case skills_sorted do
      [] ->
        message
        |> not_understood(bot)
      skills ->
        higher_confidence_skill = Enum.at(skills, 0)

        difference = case Enum.count(skills) do
          1 -> higher_confidence_skill["confidence"]
          _ -> higher_confidence_skill["confidence"] - Enum.at(skills, 1)["confidence"]
        end

        if bot.front_desk.threshold <= difference do
          Skill.respond(higher_confidence_skill["skill"], message)
        else
          message
          |> clarification(bot, Enum.map(skills, fn(skill) -> skill["skill"] end))
        end
    end
  end

  defp language_detector(bot, message) do
    skills = bot.skills
    |> Enum.filter(fn(skill) ->
      is_language_detector?(skill)
    end)

    case skills do
      [skill] ->
        if Skill.confidence(skill, message) > 0 do
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

  def find_skill(bot, skill_id) do
    skills = bot.skills
    |> Enum.filter(fn(skill) ->
      Skill.id(skill) == skill_id
    end)

    case skills do
      [skill] -> skill
      [] -> Logger.info "Skill not found #{skill_id}"
      _ -> Logger.info "Duplicated skill id #{skill_id}"
    end
  end
end
