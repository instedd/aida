defmodule AidaWeb.Channel.WebSocketTest do
  alias AidaWeb.BotChannel
  alias Aida.{BotManager, BotParser, ChannelRegistry, DB, DB.Session, DB.Image, Repo, DB.MessageLog}
  use AidaWeb.ChannelCase

  setup do
    manifest = File.read!("test/fixtures/valid_manifest.json") |> Poison.decode!()
    {:ok, db_bot} = DB.create_bot(%{manifest: manifest})
    {:ok, bot} = BotParser.parse(db_bot.id, manifest)
    ChannelRegistry.start_link
    BotManager.start_link
    BotManager.start(bot)

    {:ok, bot: bot}
  end

  test "fail to join if the bot doesn't exist" do
    assert {:error, %{reason: "unauthorized"}} = socket()
      |> subscribe_and_join(BotChannel, "bot:2f6dc44d-dad1-4969-b22f-729c3b77f638", %{"access_token" => "1234"})
  end

  test "fail to join if the bot doesn't have a websocket channel", %{bot: bot} do
    BotManager.start(%{bot | channels: []})
    assert {:error, %{reason: "unauthorized"}} = socket()
      |> subscribe_and_join(BotChannel, "bot:#{bot.id}", %{"access_token" => "qwertyuiopasdfghjklzxcvbnm"})
  end

  test "fail to join if the access token is invalid", %{bot: bot} do
    assert {:error, %{reason: "unauthorized"}} = socket()
      |> subscribe_and_join(BotChannel, "bot:#{bot.id}", %{"access_token" => "1234"})
  end

  test "join to an existing bot", %{bot: bot} do
    assert {:ok, _, _} = socket()
      |> subscribe_and_join(BotChannel, "bot:#{bot.id}", %{"access_token" => "qwertyuiopasdfghjklzxcvbnm"})
  end

  test "start new session", %{bot: bot} do
    socket()
      |> subscribe_and_join!(BotChannel, "bot:#{bot.id}", %{"access_token" => "qwertyuiopasdfghjklzxcvbnm"})
      |> push("new_session")
      |> assert_reply(:ok, %{session: session_id})

    assert %Session{
      id: ^session_id,
      data: %{}
    } = Session.get(session_id)
  end

  test "start new session with data", %{bot: bot} do
    data = %{"first_name" => "John", "last_name" => "Doe"}

    socket()
      |> subscribe_and_join!(BotChannel, "bot:#{bot.id}", %{"access_token" => "qwertyuiopasdfghjklzxcvbnm"})
      |> push("new_session", %{"data" => data})
      |> assert_reply(:ok, %{session: session_id})

    assert %Session{
      id: ^session_id,
      data: ^data
    } = Session.get(session_id)
  end

  test "push data to be merged in the session", %{bot: bot} do
    data = %{"first_name" => "John", "last_name" => "Doe"}
    new_data = %{"gender" => "male"}

    socket = socket()
      |> subscribe_and_join!(BotChannel, "bot:#{bot.id}", %{"access_token" => "qwertyuiopasdfghjklzxcvbnm"})

    socket |> push("new_session", %{"data" => data})
      |> assert_reply(:ok, %{session: session_id})

    socket |> push("put_data", %{"session" => session_id, "data" => new_data})
      |> assert_reply(:ok, _)

    data = data |> Map.merge(new_data)

    assert Session.get(session_id).data == data
  end

  test "bot answers a utb message", %{bot: bot} do
    socket = socket()
      |> subscribe_and_join!(BotChannel, "bot:#{bot.id}", %{"access_token" => "qwertyuiopasdfghjklzxcvbnm"})

    socket |> push("new_session")
      |> assert_reply(:ok, %{session: session_id})

    socket |> push("utb_msg", %{"session" => session_id, "text" => "Hi!"})

    assert_push("btu_msg", %{session: ^session_id, text: "To chat in english say 'english' or 'inglés'. Para hablar en español escribe 'español' o 'spanish'"}, 1000)
  end

  describe "images" do
    setup do
      manifest = File.read!("test/fixtures/valid_manifest_images.json") |> Poison.decode!()
      {:ok, db_bot} = DB.create_bot(%{manifest: manifest})
      {:ok, bot} = BotParser.parse(db_bot.id, manifest)
      ChannelRegistry.start_link
      BotManager.start_link
      BotManager.start(bot)

      socket = socket()
      |> subscribe_and_join!(BotChannel, "bot:#{bot.id}", %{"access_token" => "qwertyuiopasdfghjklzxcvbnm"})
      socket |> push("new_session")
        |> assert_reply(:ok, %{session: session_id})
      socket |> push("utb_msg", %{"session" => session_id, "text" => "survey"})
      assert_push("btu_msg", %{session: ^session_id, text: "Can you send me a picture?"}, 1000)

      {:ok, binary} = File.read("test/fixtures/file_upload_test.png")
      image = %Image{} |> Image.changeset(%{binary: binary, binary_type: "image/jpeg", source_url: nil, bot_id: bot.id, session_id: session_id}) |> Repo.insert!

      {:ok, image: image, socket: socket}
    end

    test "bot answers a utb image message", %{image: %{uuid: image_uuid, session_id: session_id}, socket: socket} do
      socket |> push("utb_img", %{"session" => session_id, "image" => image_uuid})
      assert_push("btu_msg", %{session: ^session_id, text: "Nice!"}, 1000)
    end

    test "bot answers a utb image message with no image", %{image: %{session_id: session_id}, socket: socket} do
      socket |> push("utb_img", %{"session" => session_id, "image" => "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB"})
      assert_push("btu_msg", %{session: ^session_id, text: "Can you send me a picture?"}, 1000)
      assert(MessageLog |> Repo.get_by!(content: "invalid_image:BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB"))
    end

    test "bot answers a utb image from a different session with no image", %{image: %{uuid: image_uuid}, socket: socket} do
      socket
      |> push("new_session")
      |> assert_reply(:ok, %{session: new_session_id})
      socket
      |> push("utb_msg", %{"session" => new_session_id, "text" => "survey"})
      assert_push("btu_msg", %{session: ^new_session_id, text: "Can you send me a picture?"}, 1000)

      socket
      |> push("utb_img", %{"session" => new_session_id, "image" => image_uuid})

      assert_push("btu_msg", %{session: ^new_session_id, text: "Can you send me a picture?"}, 1000)
      assert(MessageLog |> Repo.get_by!(content: "invalid_image:#{image_uuid}"))
    end
  end
end
