defmodule Aida.WitAiTest do
  use Aida.DataCase
  use Aida.SessionHelper
  import Mock

  alias Aida.{Bot, BotParser, Engine.WitAi}

  @auth_token "CFF627A3548C4EDABE7CAC9FF91BC98B"
  @bot_id "f905a698-310f-473f-b2d0-00d30ad58b0c"
  @skill_id "f4c74ff9-e393-4ae1-a53e-b1e98a4c0401"

  defmacro with_http_mock(do: yield) do
    quote do
      with_mock HTTPoison,
        post: fn _, _, _ -> {:ok, %{status_code: 200}} end,
        delete: fn _, _ -> {:ok, %{status_code: 200}} end,
        get: fn _, _ -> {:ok, %{status_code: 200}} end do
        unquote(yield)
      end
    end
  end

  defmacro with_failing_http_mock(do: yield) do
    quote do
      response = %{status_code: 404, body: %{"error" => "not found"} |> Poison.encode!()}

      with_mock HTTPoison,
        post: fn _, _, _ -> {:ok, response} end,
        delete: fn _, _ -> {:ok, response} end,
        get: fn _, _ -> {:ok, response} end do
        unquote(yield)
      end
    end
  end

  test "check credentials" do
    with_http_mock do
      assert WitAi.check_credentials(@auth_token) == :ok

      assert called(
               HTTPoison.get(
                 "https://api.wit.ai/message?v=20180815&q=hello",
                 %{"Authorization" => "Bearer #{@auth_token}"}
               )
             )
    end
  end

  test "delete existing entities" do
    with_http_mock do
      assert WitAi.delete_existing_entity_if_any(@auth_token, @bot_id) == :ok

      assert called(
               HTTPoison.delete(
                 "https://api.wit.ai/entities/#{@bot_id}?v=20180815",
                 %{"Authorization" => "Bearer #{@auth_token}"}
               )
             )
    end
  end

  test "doesn't break when trying to delete unexisting entities" do
    with_failing_http_mock do
      assert WitAi.delete_existing_entity_if_any(@auth_token, @bot_id) == :ok

      assert called(
               HTTPoison.delete(
                 "https://api.wit.ai/entities/#{@bot_id}?v=20180815",
                 %{"Authorization" => "Bearer #{@auth_token}"}
               )
             )
    end
  end

  test "create entity" do
    with_http_mock do
      assert WitAi.create_entity(@auth_token, @bot_id) == :ok

      assert called(
               HTTPoison.post(
                 "https://api.wit.ai/entities?v=20180815",
                 %{"id" => @bot_id} |> Poison.encode!(),
                 %{
                   "Authorization" => "Bearer #{@auth_token}",
                   "Content-Type" => "application/json"
                 }
               )
             )
    end
  end

  test "upload sample" do
    with_http_mock do
      training_set = ["first training sentence", "second training sentence"]

      assert WitAi.upload_sample(@auth_token, @bot_id, training_set, @skill_id) == :ok

      headers = %{
        "Authorization" => "Bearer #{@auth_token}",
        "Content-Type" => "application/json"
      }

      payload = [
        %{
          "text" => "first training sentence",
          "entities" => [
            %{
              "entity" => @bot_id,
              "value" => @skill_id
            }
          ]
        },
        %{
          "text" => "second training sentence",
          "entities" => [
            %{
              "entity" => @bot_id,
              "value" => @skill_id
            }
          ]
        }
      ]

      assert called(
               HTTPoison.post(
                 "https://api.wit.ai/samples?v=20180815",
                 payload |> Poison.encode!(),
                 headers
               )
             )
    end
  end

  test "bot pulbishing" do
    with_mock WitAi, [
      {:check_credentials, fn _valid_auth_token -> :ok end},
      {:delete_existing_entity_if_any, fn _auth_token, _bot_id -> :ok end},
      {:create_entity, fn _auth_token, _bot_id -> :ok end},
      {:upload_sample, fn _auth_token, _bot_id, _training_sentences, _value -> :ok end}
    ] do
      manifest = File.read!("test/fixtures/valid_manifest_with_wit_ai.json") |> Poison.decode!()

      {:ok, bot} = BotParser.parse(@bot_id, manifest)
      Bot.init(bot)

      assert called(WitAi.delete_existing_entity_if_any("valid auth_token", @bot_id))
      assert called(WitAi.create_entity("valid auth_token", @bot_id))

      assert called(
               WitAi.upload_sample(
                 "valid auth_token",
                 @bot_id,
                 ["I need some menu information", "What food do you serve?"],
                 @skill_id
               )
             )
    end
  end
end
