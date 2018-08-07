defmodule FacebookApi do
  @type t :: %__MODULE__{
          access_token: String.t()
        }

  defstruct [:access_token]

  defmodule Error do
    defexception [:message, :code, :http_response]

    def exception(message, code, http_response) do
      %__MODULE__{message: message, code: code, http_response: http_response}
    end
  end

  @spec new(access_token :: String.t()) :: t
  def new(access_token) do
    %FacebookApi{access_token: access_token}
  end

  @spec send_message(api :: t, recipient :: String.t(), message :: String.t()) :: :ok
  def send_message(api, recipient, message) do
    url = "https://graph.facebook.com/v2.6/me/messages?access_token=#{api.access_token}"
    headers = [{"Content-type", "application/json"}]
    body = %{recipient: %{id: recipient}, message: %{text: message}, messaging_type: "RESPONSE"}
    response = HTTPoison.post!(url, Poison.encode!(body), headers)
    handle_errors(response)
    :ok
  end

  @spec get_profile(api :: t, psid :: String.t()) :: map
  def get_profile(api, psid) do
    url = "https://graph.facebook.com/v2.6/#{psid}?access_token=#{api.access_token}"
    response = HTTPoison.get!(url) |> handle_errors
    Poison.decode!(response.body)
  end

  defp handle_errors(response) do
    case response.status_code do
      200 ->
        response

      _ ->
        case Poison.decode(response.body) do
          {:ok, %{"error" => %{"message" => message, "code" => code}}} ->
            raise FacebookApi.Error.exception(message, code, response)

          _ ->
            raise FacebookApi.Error.exception("Unknown error", -1, response)
        end
    end
  end
end
