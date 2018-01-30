defmodule Aida.TestSkill do
  defstruct [
    encrypt: false,
    response: "This is a test"
  ]

  defimpl Aida.Skill, for: __MODULE__ do
    alias Aida.Message

    def explain(_skill, msg), do: msg

    def clarify(_skill, msg), do: msg

    def confidence(_skill, _msg), do: :threshold

    def put_response(%{response: response}, msg), do: msg |> Message.respond(response) |> Message.mark_sensitive

    def id(_skill), do: "test_skill"

    def init(skill, _bot), do: skill

    def wake_up(_skill, _bot, _data), do: :ok

    def relevant(_skill), do: nil
  end
end
