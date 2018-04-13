defmodule Aida.DB.Session do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias Aida.Ecto.Type.JSON
  alias Aida.DB.MessageLog
  alias Aida.Repo
  alias Aida.Crypto
  alias __MODULE__

  @primary_key {:id, :binary_id, autogenerate: false}
  schema "sessions" do
    field :data, JSON, default: %{}
    field :bot_id, :binary_id
    field :provider, :string
    field :provider_key, :string
    field :is_new?, :boolean, virtual: true, default: false

    timestamps()
  end

  @type value :: Poison.Parser.t
  @typep data :: %{required(String.t) => value}

  @type t :: %__MODULE__{
    id: String.t,
    data: data,
    bot_id: String.t,
    provider: String.t,
    provider_key: String.t,
    is_new?: boolean
  }


  def new(id \\ Ecto.UUID.generate)

  @spec new(%{bot_id: String.t, provider: String.t, provider_key: String.t}) :: t
  def new(%{bot_id: bot_id, provider: provider, provider_key: provider_key}) do
    %Session{
      id: Ecto.UUID.generate,
      bot_id: bot_id,
      provider: provider,
      provider_key: provider_key,
      is_new?: true
    }
  end

  @spec new(String.t) :: t
  def new(id) when is_binary(id) do
    %Session{
      id: id,
      is_new?: true
    }
  end

  @spec new({String.t, data}) :: t
  def new({id, values})
      when is_binary(id) and is_map(values) do
    %Session{
      id: id,
      data: values
    }
  end

  # @spec load(String.t) :: Session
  def load(%{bot_id: bot_id, provider: provider, provider_key: provider_key} = session_struct) do
    s = Session
      |> where([s], s.bot_id == ^bot_id)
      |> where([s], s.provider == ^provider)
      |> where([s], s.provider_key == ^provider_key)
      |> Repo.one

    case s do
      nil -> new(session_struct)
      session -> session
    end
  end

  @spec merge(t, data) :: t
  def merge(%Session{data: data} = session, new_data) do
    %{session | data: Map.merge(data, new_data)}
  end

  @spec delete(id :: String.t) :: :ok
  def delete(id) do
    Session
      |> where([s], s.id == ^id)
      |> Repo.delete_all

    :ok
  end

  @doc """
  Returns the session for the given id. If the session does not exist, it returns `nil`.
  """
  def get(id) do
    Session |> Repo.get(id)
  end

  def session_index_by_bot(bot_id) do
    Session
      |> join(:inner, [s], m in MessageLog, m.session_id == s.id)
      |> where([s], s.bot_id == ^bot_id)
      |> where([_, m], m.direction == "incoming")
      |> group_by([s, m], s.id)
      |> select([s, m], %{id: s.id, first_message: min(m.inserted_at), last_message: max(m.inserted_at)})
      |> Repo.all()
  end

  def message_logs_by_session(session_id) do
    MessageLog
      |> where([m], m.session_id == ^session_id)
      |> select([m], %{timestamp: m.inserted_at, direction: m.direction, content: m.content, content_type: m.content_type})
      |> Repo.all
  end

  @doc false
  def changeset(%Session{} = session, attrs) do
    session
    |> cast(attrs, [:id, :data, :bot_id, :provider, :provider_key])
    |> validate_required([:id, :data, :bot_id, :provider, :provider_key])
  end

  def save(%Session{} = session) do
    session
      |> Session.changeset(%{is_new?: false})
      |> Repo.insert!(on_conflict: :replace_all, conflict_target: :id)
  end

  def save(id, data) do
    %Session{}
      |> Session.changeset(%{id: id, data: data})
      |> Repo.insert!(on_conflict: :replace_all, conflict_target: :id)
  end

  def update(%Session{} = session) do
    session
      |> Session.changeset(%{data: session.data, is_new?: false})
      |> Repo.update
  end

  @spec encrypt_id(id :: String.t, bot_id :: String.t) :: binary
  def encrypt_id(id, bot_id) do
    salt = salt_from_id(bot_id)
    Crypto.server_encrypt(id, salt) |> Base.encode16
  end

  @spec decrypt_id(encrypted_id :: binary, bot_id :: String.t) :: String.t
  def decrypt_id(encrypted_id, bot_id) do
    salt = salt_from_id(bot_id)
    encrypted_id
      |> Base.decode16!
      |> Crypto.server_decrypt(salt)
  end

  defp salt_from_id(bot_id) do
    <<salt :: binary-size(24)>> <> _ = bot_id
    salt
  end

  @spec get(session :: t, key :: String.t) :: value
  def get(%Session{data: data}, key) do
    Map.get(data, key)
  end

  @spec put(session :: t, key :: String.t, value :: value) :: t
  def put(%Session{data: data} = session, key, nil) do
    %{session | data: Map.delete(data, key)}
  end

  def put(%Session{data: data} = session, key, value) do
    %{session | data: Map.put(data, key, value)}
  end

  @spec lookup_var(session :: t, key :: String.t) :: value
  def lookup_var(%Session{data: data} = session, key) do
    case get(session, key) do
      nil ->
        match = data |> Enum.find(fn {k, _} -> k |> String.ends_with?("/#{key}") end)
        case match do
          {_, value} -> value
          nil -> :not_found
        end

      value -> value
    end
  end

end
