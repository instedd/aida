defmodule Aida.Skill.Survey do

  @type t :: %__MODULE__{
    id: String.t(),
    bot_id: String.t(),
    name: String.t(),
    schedule: String.t(),
    questions: [Aida.SelectQuestion.t() | Aida.InputQuestion.t()],
    choice_lists: [Aida.ChoiceList.t()]
  }

  defstruct id: "",
            bot_id: "",
            name: "",
            schedule: "",
            questions: [],
            choice_lists: []

  defimpl Aida.Skill, for: __MODULE__ do
    def init(skill, _bot) do
      skill
    end

    def wake_up(_skill, _bot) do
      :ok
    end

    def explain(%{}, message) do
      message
    end

    def clarify(%{}, message) do
      message
    end

    def put_response(_skill, message) do
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
