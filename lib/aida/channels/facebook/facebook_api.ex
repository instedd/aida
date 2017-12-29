defmodule FacebookApi do
  @type t :: %__MODULE__{
    access_token: String.t
  }

  defstruct [:access_token]

  @spec new(access_token :: String.t) :: t
  def new(access_token) do
    %FacebookApi{access_token: access_token}
  end

  @spec send_message(api :: t, recipient :: String.t, message :: String.t) :: :ok
  def send_message(api, recipient, message) do
    url = "https://graph.facebook.com/v2.6/me/messages?access_token=#{api.access_token}"
    headers = [{"Content-type", "application/json"}]
    body = %{"recipient": %{"id": recipient}, "message": %{"text": message}, "messaging_type": "RESPONSE"}
    HTTPoison.post url, Poison.encode!(body), headers
    :ok
  end

  @spec get_profile(api :: t, psid :: String.t) :: map
  def get_profile(api, psid) do
    url = "https://graph.facebook.com/v2.6/#{psid}?access_token=#{api.access_token}"
    response = HTTPoison.get!(url)
    Poison.decode!(response.body)
  end
end
