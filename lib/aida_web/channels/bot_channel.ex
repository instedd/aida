defmodule AidaWeb.BotChannel do
  use Phoenix.Channel
  alias Aida.{Session, BotManager, Bot, Message, Channel.WebSocket, DB.MessageLog}

  def join("bot:" <> bot_id, %{"access_token" => access_token}, socket) do
    case WebSocket.find_channel_for_bot(bot_id) do
      %WebSocket{access_token: ^access_token} ->
        socket = assign(socket, :bot_id, bot_id)
        {:ok, socket}
      _ ->
        {:error, %{reason: "unauthorized"}}
    end
  end

  def handle_in("new_session", attrs, socket) do
    session_id = Ecto.UUID.generate
    data = case attrs do
      %{"data" => %{} = data} -> data
      _ -> %{}
    end

    Session.new({real_session_id(socket, session_id), Ecto.UUID.generate, data})
      |> Session.save

    {:reply, {:ok, %{session: session_id}}, socket}
  end

  def handle_in("put_data", %{"session" => session_id, "data" => data}, socket) do
    Session.load(real_session_id(socket, session_id))
      |> Session.merge(data)
      |> Session.save

    {:reply, :ok, socket}
  end

  def handle_in("delete_session", %{"session" => session_id}, socket) do
    Session.delete(real_session_id(socket, session_id))
    {:reply, :ok, socket}
  end

  def handle_in("utb_msg", %{"text" => text, "session" => session_id}, socket) do
    case BotManager.find(socket.assigns.bot_id) do
      :not_found -> {:stop, :not_found, socket}
      bot ->
        real_session_id = real_session_id(socket, session_id)
        session = Session.load(real_session_id)
        MessageLog.create(%{bot_id: bot.id, session_id: real_session_id, session_uuid: Session.uuid(session), content: text, content_type: "text", direction: "incoming"})
        reply = Bot.chat(bot, Message.new(text, bot, session))
        reply.session |> Session.save

        reply.reply |> Enum.each(fn message ->
          push socket, "btu_msg", %{text: message, session: session_id}
        end)
        {:noreply, socket}
    end
  end

  defp real_session_id(socket, session_id) do
    "#{socket.assigns.bot_id}/ws/#{session_id}"
  end
end
