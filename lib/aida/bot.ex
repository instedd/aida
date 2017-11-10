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
      Enum.count(bot.languages) == 1 ->
        message
        |> put_session("language", bot.languages |> List.first)
        |> greet(bot)
    end
  end

  defp greet(%Message{} = message, bot) do
    message = message
    |> respond(bot.front_desk.greeting)
    |> respond(bot.front_desk.introduction)

    bot.skills
    |> Enum.reduce(message, fn(skill, message) ->
      Skill.explain(skill, message)
    end)
  end
end
