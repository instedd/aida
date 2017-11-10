defmodule Aida.Bot do
  alias Aida.{FrontDesk, Variable, Message, Skill}
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
      new_session?(message) && !get_session(message, "language") && Enum.count(bot.languages) == 1 ->
        message
        |> put_session("language", bot.languages |> List.first)
        |> greet(bot)
      get_session(message, "language") ->
        message
        |> respond(bot.front_desk.not_understood)
        |> introduction(bot)
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
      Skill.explain(skill, message)
    end)
  end
end
