defmodule AidaWeb.WitAIController do
  use AidaWeb, :controller

  alias Aida.Engine.WitAIEngine

  def check_credentials(conn, %{"provider" => "wit_ai"} = params) do
    with :ok <- WitAIEngine.check_credentials(params) do
      conn |> send_resp(200, "")
    else
      {:error, response} ->
        conn |> put_status(422) |> json(%{errors: response}) |> halt
    end
  end
end
