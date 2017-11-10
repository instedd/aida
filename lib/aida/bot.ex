defmodule Aida.Bot do
  alias Aida.{FrontDesk, Variable, Message}
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
  def chat(bot, message) do
    language = bot.languages |> List.first

    message
    |> respond(bot.front_desk.greeting[language])
    |> respond(bot.front_desk.introduction[language])
  end
end
