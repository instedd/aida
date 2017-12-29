defmodule AidaWeb.BotChannel do
  use Phoenix.Channel
  alias Aida.{Session, BotManager, DB, Bot, Message}

  def join("bot:" <> bot_id, _params, socket) do
    case DB.get_bot!(bot_id) do
      nil -> {:error, %{reason: "unauthorized"}}
      _bot ->
        socket = assign(socket, :bot_id, bot_id)
        {:ok, socket}
    end
  end

  def handle_in("new_session", _message, socket) do
    session_id = Ecto.UUID.generate
    session = Session.new("#{socket.assigns.bot_id}/ws/#{session_id}")
    session |> Session.save
    {:reply, {:ok, %{session: session_id}}, socket}
  end

  def handle_in("delete_session", %{"session" => session_id}, socket) do
    Session.delete("#{socket.assigns.bot_id}/ws/#{session_id}")
    {:reply, :ok , socket}
  end

  def handle_in("utb_msg", %{"text" => text, "session" => session_id}, socket) do
    case BotManager.find(socket.assigns.bot_id) do
      :not_found -> {:stop, :not_found, socket}
      bot ->
        session = Session.load("#{socket.assigns.bot_id}/ws/#{session_id}")
        reply = Bot.chat(bot, Message.new(text, session))
        reply.session |> Session.save

        reply.reply |> Enum.each fn message ->
          push socket, "btu_msg", %{text: message, session: session_id}
        end
        {:noreply, socket}
    end
  end
end
