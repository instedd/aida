defmodule AidaWeb.WitAiController do
  use AidaWeb, :controller

  alias Aida.WitAi

  def check_credentials(conn, %{"provider" => "wit_ai"} = params) do
    with {:ok, _} <- WitAi.check_credentials(params["auth_token"]) do
      conn |> send_resp(200, "")
    else
      {:error, response} ->
        conn |> put_status(422) |> json(%{errors: response}) |> halt
    end
  end
end
