defmodule Aida.Engine.WitAIEngine do
  def check_credentials(%{"auth_token" => token}) do
    url = "https://api.wit.ai/message?v=20180815&q=hello"
    headers = %{"Authorization" => "Bearer #{token}"}

    case HTTPoison.get(url, headers) do
      {:ok, %{status_code: 200}} -> :ok
      {:ok, response} -> {:error, response.body |> Poison.decode!()}
      response -> {:error, response}
    end
  end

  def check_credentials(_), do: {:error, "Authorization token expected"}

  defimpl Aida.Engine, for: __MODULE__ do
    @spec confidence(message :: Aida.Message.t()) :: :ok
    def confidence(_message), do: :ok
  end
end
