defmodule AidaWeb.BotChannel do
  use Phoenix.Channel
  alias Aida.{BotManager, Bot, Message, Channel.WebSocket, DB}
  alias Aida.DB.{Session, Image}

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
    data = case attrs do
      %{"data" => %{} = data} -> data
      _ -> %{}
    end

    session = Session.new({socket.assigns.bot_id, "ws", Ecto.UUID.generate})
      |> Session.merge(data)
      |> Session.save

    {:reply, {:ok, %{session: session.id}}, socket}
  end

  def handle_in("put_data", %{"session" => session_id, "data" => data}, socket) do
    Session.get(session_id)
      |> Session.merge(data)
      |> Session.save

    {:reply, :ok, socket}
  end

  def handle_in("delete_session", %{"session" => session_id}, socket) do
    Session.delete(session_id)
    {:reply, :ok, socket}
  end

  def handle_in("utb_msg", %{"text" => text, "session" => session_id}, socket) do
    case BotManager.find(socket.assigns.bot_id) do
      :not_found -> {:stop, :not_found, socket}
      bot ->
        session = Session.get(session_id)
        reply = Bot.chat(Message.new(text, bot, session))
        reply.session |> Session.save

        reply.reply |> Enum.each(fn message ->
          push socket, "btu_msg", %{text: message, session: session_id}
        end)
        {:noreply, socket}
    end
  end

  def handle_in("utb_img", %{"image" => image_uuid, "session" => session_id}, socket) do
    bot_id = socket.assigns.bot_id
    case BotManager.find(bot_id) do
      :not_found -> {:stop, :not_found, socket}
      bot ->
        session = Session.get(session_id)
        message = case DB.get_image(image_uuid) do
          %Image{bot_id: ^bot_id, session_id: ^session_id} -> Message.new_from_image(%{uuid: image_uuid}, bot, session)
          _ -> Message.invalid_image(%{uuid: image_uuid}, bot, session)
        end

        reply = Bot.chat(message)
        reply.session |> Session.save

        reply.reply |> Enum.each(fn message ->
          push socket, "btu_msg", %{text: message, session: session_id}
        end)
        {:noreply, socket}
    end
  end

end
