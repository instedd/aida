defmodule Aida.SessionHelper do
  defmacro __using__(_) do
    quote do
      alias Aida.DB.Session

      def new_session({id, values}) when is_binary(id) and is_map(values) do
        %Session{
          id: id,
          data: values,
          bot_id: Ecto.UUID.generate,
          is_new?: true,
          provider: "facebook",
          provider_key: "1234/5678"
        }
      end
    end
  end
end
