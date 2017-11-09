defmodule Aida.Variable do
  @type t :: %__MODULE__{
    name: String.t,
    values: map
  }

  defstruct name: nil,
            values: %{}
end
