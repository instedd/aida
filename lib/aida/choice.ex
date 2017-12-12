defmodule Aida.Choice do
  alias __MODULE__

  @type t :: %__MODULE__{
    name: String.t(),
    labels: %{}
  }

  defstruct name: "",
            labels: %{}


  def name(%Choice{name: name}) do
    name
  end
end
