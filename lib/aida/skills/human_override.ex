defmodule Aida.Skill.HumanOverride do
  alias Aida.{Bot, Message, Message.TextContent, Skill.Utils}

  @type t :: %__MODULE__{
    explanation: Bot.message,
    clarification: Bot.message,
    id: String.t(),
    bot_id: String.t(),
    name: String.t(),
    keywords: %{},
    in_hours_response: %{},
    off_hours_response: %{},
    relevant: nil | Aida.Expr.t
  }

  defstruct explanation: %{},
            clarification: %{},
            id: "",
            bot_id: "",
            name: "",
            keywords: %{},
            in_hours_response: %{},
            off_hours_response: %{},
            relevant: nil

  defimpl Aida.Skill, for: __MODULE__ do
    def init(skill, _bot), do: skill

    def clear_state(_skill, message), do: message

    def wake_up(_skill, _bot, _data), do: :ok

    def explain(%{explanation: explanation}, message) do
      message |> Message.respond(explanation)
    end

    def clarify(%{clarification: clarification}, message) do
      message |> Message.respond(clarification)
    end

    def put_response(%{in_hours_response: response}, %{bot: bot} = message) do
      Bot.notify(bot, :human_override, %{message: Message.text_content(message), session_id: message.session.id, name: Message.get_session(message, "first_name")})
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

    def uses_encryption?(_), do: false
  end
end
