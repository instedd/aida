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

  @spec new(id :: String.t) :: t
  def new(id \\ Ecto.UUID.generate) do
    %Session{
      id: id,
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

  def get(%Session{values: values}, key) do
    Map.get(values, key)
  end

  def put(%Session{values: values} = session, key, value) do
    %{session | values: Map.put(values, key, value)}
  end
end
