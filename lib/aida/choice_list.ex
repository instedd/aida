defmodule Aida.ChoiceList do
  @type t :: %__MODULE__{
    name: String.t(),
    choices: [Aida.Choice.t()]
  }

  defstruct name: "",
            choices: []

end
