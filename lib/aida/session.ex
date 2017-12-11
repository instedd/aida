defmodule Aida.Session do
  alias __MODULE__
  alias Aida.SessionStore

  @type value :: Poison.Parser.t
  @typep values :: %{required(String.t) => value}
  @type t :: %__MODULE__{
    id: String.t,
    is_new?: boolean,
    values: values
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

  @spec new(id :: String.t, values :: values) :: t
  def new(id, values) do
    %Session{
      id: id,
      values: values
    }
  end

  @spec load(id :: String.t) :: t
  def load(id) do
    case SessionStore.find(id) do
      :not_found -> new(id)
      data -> new(id, data)
    end
  end

  @spec save(session :: t) :: :ok
  def save(session) do
    SessionStore.save(session.id, session.values)
  end

  @spec delete(id :: String.t) :: :ok
  def delete(id) do
    SessionStore.delete(id)
  end

  @spec get(session :: Session.t, key :: String.t) :: value
  def get(%Session{values: values}, key) do
    Map.get(values, key)
  end

  @spec put(session :: Session.t, key :: String.t, value :: value) :: t
  def put(%Session{values: values} = session, key, value) do
    %{session | values: Map.put(values, key, value)}
  end

  @spec is_new?(session :: Session.t) :: boolean
  def is_new?(%Session{is_new?: value}) do
    value
  end
end
