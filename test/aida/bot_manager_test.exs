defmodule Aida.BotManagerTest do
  use Aida.DataCase
  use Aida.TimeMachine
  alias Aida.{DB, Bot, BotManager, BotParser, TestChannel, ChannelRegistry, Scheduler}
  import Mock

  @uuid "f1168bcf-59e5-490b-b2eb-30a4d6b01e7b"

  describe "with BotManager running" do
    setup do
      ChannelRegistry.start_link
      BotManager.start_link
      Scheduler.start_link
      :ok
    end

    test "find non existing bot returns :not_found" do
      assert BotManager.find(@uuid) == :not_found
    end

    test "start and find bot" do
      bot = %Bot{id: @uuid}
      assert BotManager.start(bot) == :ok
      assert BotManager.find(@uuid) == bot
    end

    test "stop bot" do
      bot = %Bot{id: @uuid}
      assert BotManager.start(bot) == :ok
      assert BotManager.stop(@uuid) == :ok
      assert BotManager.find(@uuid) == :not_found
    end

    test "stopping an invalid bot returns :not_found" do
      assert BotManager.stop("44837101-dace-4caa-a816-f0c34d168121") == :not_found
    end

    test "channels are started and stopped with the bot" do
      channel = TestChannel.new()
      bot = %Bot{id: @uuid, channels: [channel]}

      BotManager.start(bot)
      assert_received {:start, ^channel}

      BotManager.stop(bot.id)
      assert_received {:stop, ^channel}
    end

    test "channels are restarted when the bot is started again" do
      channel = TestChannel.new()
      bot = %Bot{id: @uuid, channels: [channel]}

      BotManager.start(bot)
      assert_received {:start, ^channel}

      BotManager.start(bot)
      assert_received {:stop, ^channel}
      assert_received {:start, ^channel}
    end

    test "schedule wake up" do
      bot = %Bot{id: @uuid}
      skill = %{id: "skill_id"}
      BotManager.start(bot)

      with_mock Bot, [wake_up: fn(_bot, _skill_id, _data) -> :ok end] do
        BotManager.schedule_wake_up(bot, skill, within(hours: 1))
        refute called Bot.wake_up(bot, "skill_id", nil)

        time_travel(within(hours: 1)) do
          assert called Bot.wake_up(bot, "skill_id", nil)
        end
      end
    end

    test "schedule wake up with data" do
      bot = %Bot{id: @uuid}
      skill = %{id: "skill_id"}
      BotManager.start(bot)

      with_mock Bot, [wake_up: fn(_bot, _skill_id, _data) -> :ok end] do
        BotManager.schedule_wake_up(bot, skill, "foo", within(hours: 1))

        time_travel(within(hours: 1)) do
          assert called Bot.wake_up(bot, "skill_id", "foo")
        end
      end
    end

    test "scheduling a second wake up for the same skill unschedule the first one" do
      bot = %Bot{id: @uuid}
      skill = %{id: "skill_id"}
      BotManager.start(bot)

      with_mock Bot, [wake_up: fn(_bot, _skill_id, _data) -> :ok end] do
        BotManager.schedule_wake_up(bot, skill, within(hours: 1))
        BotManager.schedule_wake_up(bot, skill, within(hours: 2))
        refute called Bot.wake_up(bot, "skill_id", nil)

        time_travel(within(hours: 1)) do
          refute called Bot.wake_up(bot, "skill_id", nil)
        end

        time_travel(within(hours: 2)) do
          assert called Bot.wake_up(bot, "skill_id", nil)
        end
      end
    end

    test "stopping the bot unschedule all the wake ups" do
      bot = %Bot{id: @uuid}
      skill = %{id: "skill_id"}
      BotManager.start(bot)

      with_mock Bot, [wake_up: fn(_bot, _skill_id, _data) -> :ok end] do
        BotManager.schedule_wake_up(bot, skill, within(hours: 1))
        BotManager.stop(bot.id)

        time_travel(within(hours: 1)) do
          refute called Bot.wake_up(:_, :_, :_)
        end
      end
    end

    test "do not crash if the wake_up call raises" do
      bot = %Bot{id: @uuid}
      skill = %{id: "skill_id"}
      BotManager.start(bot)

      with_mock Bot, [wake_up: fn(_bot, _skill_id, _data) -> raise "error" end] do
        BotManager.schedule_wake_up(bot, skill, within(hours: 1))

        time_travel(within(hours: 1)) do
          assert called Bot.wake_up(bot, "skill_id", nil)
          assert GenServer.whereis({:global, BotManager})
        end
      end
    end
  end

  test "loads existing bots when it starts" do
    manifest = File.read!("test/fixtures/valid_manifest.json") |> Poison.decode!
    {:ok, db_bot} = DB.create_bot(%{manifest: manifest})

    {:ok, bot} = BotParser.parse(db_bot.id, manifest)

    ChannelRegistry.start_link
    BotManager.start_link

    assert BotManager.find(bot.id) == bot
  end

  test "loads valid bots and skips invalid ones on start" do
    manifest = File.read!("test/fixtures/valid_manifest.json") |> Poison.decode!
    {:ok, db_bot} = DB.create_bot(%{manifest: manifest})
    {:ok, bot} = BotParser.parse(db_bot.id, manifest)

    invalid_manifest = manifest
        |> Map.put("skills", [
          %{
            "type" => "keyword_responder",
            "id" => "this is the same id",
            "name" => "Food menu",
            "explanation" => %{
              "en" => "I can give you information about our menu",
              "es" => "Te puedo dar información sobre nuestro menu"
            },
            "clarification" => %{
              "en" => "For menu options, write 'menu'",
              "es" => "Para información sobre nuestro menu, escribe 'menu'"
            },
            "keywords" => %{
              "en" => ["menu","food"],
              "es" => ["menu","comida"]
            },
            "response" => %{
              "en" => "We have {food_options}",
              "es" => "Tenemos {food_options}"
            }
          },
          %{
            "type" => "keyword_responder",
            "id" => "this is the same id",
            "name" => "Opening hours",
            "explanation" => %{
              "en" => "I can give you information about our opening hours",
              "es" => "Te puedo dar información sobre nuestro horario"
            },
            "clarification" => %{
              "en" => "For opening hours say 'hours'",
              "es" => "Para información sobre nuestro horario escribe 'horario'"
            },
            "keywords" => %{
              "en" => ["hours","time"],
              "es" => ["horario","hora"]
            },
            "response" => %{
              "en" => "We are open every day from 7pm to 11pm",
              "es" => "Abrimos todas las noches de 19 a 23"
            }
          }
        ])
    {:ok, invalid_bot} = DB.create_bot(%{manifest: invalid_manifest})

    ChannelRegistry.start_link
    BotManager.start_link

    assert BotManager.find(bot.id) == bot

    assert BotManager.find(invalid_bot.id) == :not_found
  end
end
