defmodule AidaWeb.BotChannel do
  use Phoenix.Channel
  alias Aida.{Session, BotManager, Bot, Message, Channel.WebSocket}

  def join("bot:" <> bot_id, %{"access_token" => access_token}, socket) do
    case WebSocket.find_channel_for_bot(bot_id) do
      %WebSocket{access_token: ^access_token} ->
        socket = assign(socket, :bot_id, bot_id)
        {:ok, socket}
      _ ->
        {:error, %{reason: "unauthorized"}}
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

        reply.reply |> Enum.each(fn message ->
          push socket, "btu_msg", %{text: message, session: session_id}
        end)
        {:noreply, socket}
    end
  end
end
