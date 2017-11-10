defmodule Aida.Session do
  alias __MODULE__
  @type t :: %__MODULE__{
    id: String.t,
    is_new?: boolean,
    values: map
  }

  defstruct id: nil,
            is_new?: false,
            values: %{}

  @spec new() :: t
  def new do
    %Session{
      id: Ecto.UUID.generate,
      is_new?: true
    }
  end

  @spec new(id :: String.t, values :: map) :: t
  def new(id, values) do
    %Session{
      id: id,
      values: values
    }
  end
end