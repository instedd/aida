defmodule Aida.SelectQuestion do
  @type t :: %__MODULE__{
    type: String.t(),
    choices: String.t(),
    name: String.t(),
    message: Aida.Bot.message
  }

  defstruct type: "",
            choices: "",
            name: "",
            message: %{}

end
