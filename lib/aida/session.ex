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
      is_new?: true,
      values: %{"uuid" => Ecto.UUID.generate}
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
    SessionStore.save(session.id, session |> Session.uuid, session.values)
  end

  @spec delete(id :: String.t) :: :ok
  def delete(id) do
    SessionStore.delete(id)
  end

  @spec uuid(session :: Session.t) :: value
  def uuid(session) do
    get(session, "uuid")
  end

  @spec get(session :: Session.t, key :: String.t) :: value
  def get(%Session{values: values}, key) do
    Map.get(values, key)
  end

  @spec put(session :: Session.t, key :: String.t, value :: value) :: t
  def put(%Session{values: values} = session, key, nil) do
    %{session | values: Map.delete(values, key)}
  end

  def put(%Session{values: values} = session, key, value) do
    %{session | values: Map.put(values, key, value)}
  end

  @spec merge(session :: Session.t, new_values :: values) :: t
  def merge(%Session{values: values} = session, new_values) do
    %{session | values: Map.merge(values, new_values)}
  end

  @spec is_new?(session :: Session.t) :: boolean
  def is_new?(%Session{is_new?: value}) do
    value
  end

  @spec lookup_var(session :: t, key :: String.t) :: value
  def lookup_var(%Session{values: values} = session, key) do
    case get(session, key) do
      nil ->
        match = values |> Enum.find(fn {k, _} -> k |> String.ends_with?("/#{key}") end)
        case match do
          {_, value} -> value
          nil -> nil
        end

      value -> value
    end
  end

  def expr_context(session, options \\ []) do
    self = options[:self]
    lookup_raises = options[:lookup_raises]
    attr_lookup = options[:attr_lookup]

    %Aida.Expr.Context{
      self: self,
      var_lookup:
        fn (name) ->
          case Session.lookup_var(session, name) do
            nil ->
              if lookup_raises do
                raise Aida.Expr.UnknownVariableError.exception(name)
              else
                nil
              end
            value -> value
          end
        end,
      attr_lookup: attr_lookup
    }
  end
end
