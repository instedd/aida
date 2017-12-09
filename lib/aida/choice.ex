defmodule Aida.Choice do
  @type t :: %__MODULE__{
    name: String.t(),
    keywords: %{}
  }

  defstruct name: "",
            keywords: %{}

end
