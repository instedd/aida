# defmodule Aida.Session do
#   alias __MODULE__
#   alias Aida.{SessionStore, Crypto}

#   @type value :: Poison.Parser.t
#   @typep values :: %{required(String.t) => value}
#   @type t :: %__MODULE__{
#     id: String.t,
#     uuid: String.t,
#     is_new?: boolean,
#     values: values
#   }

#   defstruct id: nil,
#             uuid: nil,
#             is_new?: false,
#             values: %{}

#   @spec new(id :: String.t | {id :: String.t, uuid :: String.t, values}) :: t
#   @spec new(id :: String.t, uuid :: String.t) :: t

#   def new({id, uuid, values})
#       when is_binary(id) and is_binary(uuid) and is_map(values) do
#     %Session{
#       id: id,
#       uuid: uuid,
#       values: values
#     }
#   end

#   def new(id \\ Ecto.UUID.generate, uuid \\ Ecto.UUID.generate)
#       when is_binary(id) and is_binary(uuid) do
#     %Session{
#       id: id,
#       uuid: uuid,
#       is_new?: true
#     }
#   end

#   @spec load(String.t) :: t
#   def load(id) do
#     case SessionStore.find(id) do
#       :not_found -> new(id)
#       session -> new(session)
#     end
#   end

#   @spec encrypt_id(id :: String.t, bot_id :: String.t) :: binary
#   def encrypt_id(id, bot_id) do
#     salt = salt_from_id(bot_id)
#     Crypto.server_encrypt(id, salt) |> Base.encode16
#   end

#   @spec decrypt_id(encrypted_id :: binary, bot_id :: String.t) :: String.t
#   def decrypt_id(encrypted_id, bot_id) do
#     salt = salt_from_id(bot_id)
#     encrypted_id
#       |> Base.decode16!
#       |> Crypto.server_decrypt(salt)
#   end

#   defp salt_from_id(bot_id) do
#     <<salt :: binary-size(24)>> <> _ = bot_id
#     salt
#   end

#   @spec save(session :: t) :: :ok
#   def save(session) do
#     SessionStore.save(session.id, session.uuid, session.values)
#   end

#   @spec delete(id :: String.t) :: :ok
#   def delete(id) do
#     SessionStore.delete(id)
#   end

#   @spec get(session :: Session.t, key :: String.t) :: value
#   def get(%Session{values: values}, key) do
#     Map.get(values, key)
#   end

#   @spec put(session :: Session.t, key :: String.t, value :: value) :: t
#   def put(%Session{values: values} = session, key, nil) do
#     %{session | values: Map.delete(values, key)}
#   end

#   def put(%Session{values: values} = session, key, value) do
#     %{session | values: Map.put(values, key, value)}
#   end

#   @spec merge(session :: Session.t, new_values :: values) :: t
#   def merge(%Session{values: values} = session, new_values) do
#     %{session | values: Map.merge(values, new_values)}
#   end

#   @spec is_new?(session :: Session.t) :: boolean
#   def is_new?(%Session{is_new?: value}) do
#     value
#   end

#   @spec lookup_var(session :: t, key :: String.t) :: value
#   def lookup_var(%Session{values: values} = session, key) do
#     case get(session, key) do
#       nil ->
#         match = values |> Enum.find(fn {k, _} -> k |> String.ends_with?("/#{key}") end)
#         case match do
#           {_, value} -> value
#           nil -> :not_found
#         end

#       value -> value
#     end
#   end
# end
