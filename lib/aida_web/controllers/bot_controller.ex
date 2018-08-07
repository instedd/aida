defmodule AidaWeb.BotController do
  use AidaWeb, :controller
  import Aida.ErrorHandler
  alias Aida.DB
  alias Aida.DB.Bot
  alias Aida.{JsonSchema, BotParser}

  action_fallback(AidaWeb.FallbackController)

  plug(:validate_params when action in [:create, :update])

  def index(conn, _params) do
    bots = DB.list_bots()
    render(conn, "index.json", bots: bots)
  end

  def create(conn, %{"bot" => bot_params}) do
    with {:ok, %Bot{} = bot} <- DB.create_bot(bot_params) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", bot_path(conn, :show, bot))
      |> render("show.json", bot: bot)
    end
  end

  def show(conn, %{"id" => id}) do
    bot = DB.get_bot!(id)
    render(conn, "show.json", bot: bot)
  end

  def update(conn, %{"id" => id, "bot" => bot_params}) do
    bot = DB.get_bot!(id)

    with {:ok, %Bot{} = bot} <- DB.update_bot(bot, bot_params) do
      render(conn, "show.json", bot: bot)
    end
  end

  def delete(conn, %{"id" => id}) do
    bot = DB.get_bot!(id)

    with {:ok, %Bot{}} <- DB.delete_bot(bot) do
      send_resp(conn, :no_content, "")
    end
  end

  defp validate_params(conn, _params) do
    manifest = conn.params["bot"]["manifest"]

    manifest =
      if is_binary(manifest) do
        {:ok, manifest} = Poison.decode(manifest)
        manifest
      else
        manifest
      end

    case JsonSchema.validate(manifest, :manifest_v1) do
      :ok ->
        case BotParser.parse("", manifest) do
          {:ok, _} ->
            conn

          {:error, err} ->
            capture_message("Error while parsing manifest: #{get_error_message(err)}")
            conn |> put_status(422) |> json(%{errors: [err]}) |> halt
        end

      {:error, errors} ->
        capture_message(
          "Error while validating manifest",
          json_errors: errors,
          manifest: manifest
        )

        conn |> put_status(422) |> json(%{errors: errors}) |> halt
    end
  end

  defp get_error_message(%{"message" => message}) do
    message
  end

  defp get_error_message(error) do
    error
  end
end
