defmodule Aida.Skill.KeywordResponder do
  alias Aida.{Bot, Message, Message.TextContent, Skill.Utils}

  @type t :: %__MODULE__{
    explanation: Bot.message,
    clarification: Bot.message,
    id: String.t(),
    bot_id: String.t(),
    name: String.t(),
    keywords: %{},
    response: %{},
    relevant: nil | Aida.Expr.t
  }

  defstruct explanation: %{},
            clarification: %{},
            id: "",
            bot_id: "",
            name: "",
            keywords: %{},
            response: %{},
            relevant: nil

  defimpl Aida.Skill, for: __MODULE__ do
    def init(skill, _bot) do
      skill
    end

    def wake_up(_skill, _bot, _data) do
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

    def confidence(%{keywords: keywords}, %{content: %TextContent{}} = message) do
      Utils.confidence_for_keywords(keywords, message)
    end

    def confidence(_, _), do: 0

    def id(%{id: id}) do
      id
    end

    def relevant(skill), do: skill.relevant
  end
end
