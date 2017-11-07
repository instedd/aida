defmodule Aida.Bot do
  @type t :: %__MODULE__{
    uuid: String.t
  }

  defstruct [:uuid]
end
