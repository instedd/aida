defmodule Aida.Skill.ScheduledMessages do

  @type t :: %__MODULE__{
    id: String.t(),
    name: String.t(),
    schedule_type: String.t(),
    messages: [Aida.DelayedMessage.t()]
  }

  defstruct id: "",
            name: "",
            schedule_type: "",
            messages: []

  defimpl Aida.Skill, for: __MODULE__ do
    def explain(%{}, message) do
      message
    end

    def clarify(%{}, message) do
      message
    end

    def respond(%{}, message) do
      message
    end

    def confidence(%{}, _message) do
      0
    end

    def id(%{id: id}) do
      id
    end
  end
end
