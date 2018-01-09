defmodule Aida.Choice do
  alias __MODULE__

  @type t :: %__MODULE__{
    name: String.t(),
    labels: %{},
    attributes: nil | %{required(String.t) => String.t | integer}
  }

  defstruct name: "",
            labels: %{},
            attributes: nil


  def name(%Choice{name: name}) do
    name
  end
end
