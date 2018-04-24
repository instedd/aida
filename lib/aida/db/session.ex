defmodule Aida.DB.Session do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query
  alias Aida.Ecto.Type.JSON
  alias Aida.Repo
  alias Aida.Crypto
  alias __MODULE__

  @primary_key {:id, :binary_id, autogenerate: true}
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

  @spec new({String.t, String.t, String.t}) :: t
  def new({bot_id, provider, provider_key}) do
    %Session{
      id: Ecto.UUID.generate,
      bot_id: bot_id,
      provider: provider,
      provider_key: provider_key,
      is_new?: true
    } |> save
  end

  # @spec load(String.t) :: Session
  def find_or_create(bot_id, provider, provider_key) do
    s = Session
      |> where([s], s.bot_id == ^bot_id)
      |> where([s], s.provider == ^provider)
      |> where([s], s.provider_key == ^provider_key)
      |> Repo.one

    case s do
      nil -> new({bot_id, provider, provider_key})
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

  @doc false
  def changeset(%Session{} = session, attrs) do
    session
    |> cast(attrs, [:id, :data, :bot_id, :provider, :provider_key])
    |> validate_required([:id, :data, :bot_id, :provider, :provider_key])
  end

  def save(%Session{} = session) do
    session
      |> Session.changeset(%{})
      |> Repo.insert!(on_conflict: :replace_all, conflict_target: :id)
  end

  def save(id, data) do
    %Session{}
      |> Session.changeset(%{id: id, data: data})
      |> Repo.insert!(on_conflict: :replace_all, conflict_target: :id)
  end

  @doc """
  Returns all the sessions for the given bot id. If there is none, it returns an empty array.
  """
  def sessions_by_bot(bot_id) do
    Session
      |> where([s], s.bot_id == ^bot_id)
      # |> where(fragment("bot_id = ?", type(^bot_id, :binary_id)))
      |> Repo.all()
  end

  def session_ids_by_bot(bot_id) do
    Session
      |> where([s], s.bot_id == ^bot_id)
      |> select([s], s.id)
      |> Repo.all()
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

  @spec get_value(session :: t, key :: String.t) :: value
  def get_value(%Session{data: data}, key) do
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
    case get_value(session, key) do
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
