defmodule Aida.Choice do
  @type t :: %__MODULE__{
    name: String.t(),
    labels: %{}
  }

  defstruct name: "",
            labels: %{}

end
