defmodule Aida.Skill.KeywordResponder do
  alias Aida.{Bot, Message}

  @type t :: %__MODULE__{
    explanation: Bot.message,
    clarification: Bot.message,
    id: String.t(),
    name: String.t(),
    keywords: %{},
    response: %{}
  }

  defstruct explanation: %{},
            clarification: %{},
            id: "",
            bot_id: "",
            name: "",
            keywords: %{},
            response: %{}

  defimpl Aida.Skill, for: __MODULE__ do
    def init(skill, _bot) do
      skill
    end

    def wake_up(_skill, _bot) do
      :ok
    end

    def explain(%{explanation: explanation}, message) do
      message |> Message.respond(explanation)
    end

    def clarify(%{clarification: clarification}, message) do
      message |> Message.respond(clarification)
    end

    def put_response(%{response: response}, message) do
      message |> Message.respond(response)
    end

    def confidence(%{keywords: keywords}, message) do
      words_in_message = Message.curated_message(message)
      |> String.split

      matches = words_in_message
      |> Enum.filter(fn(word) ->
        Enum.member?(keywords[Message.language(message)], word)
      end)

      word_count = Enum.count(words_in_message)
      case word_count do
        0 -> 0
        _ ->Enum.count(matches)/word_count
      end
    end

    def id(%{id: id}) do
      id
    end
  end
end
