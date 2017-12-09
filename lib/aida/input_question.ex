defmodule Aida.InputQuestion do
  @type t :: %__MODULE__{
    type: String.t(),
    name: String.t(),
    message: Aida.Bot.message
  }

  defstruct type: "",
            name: "",
            message: %{}

end
