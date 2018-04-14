defmodule Aida.DecisionTreeTest do
  alias Aida.{Bot, BotParser, Message}
  alias Aida.Skill.DecisionTree
  alias Aida.DB.{Session}
  use Aida.DataCase

  @bot_id "c4cf6a74-d154-4e2f-9945-ba999b06f8bd"

  @basic_answer %{"answer" =>
                  %{"en" => "Go with an ice cream",
                    "es" => "Comete un helado"},
                "id" => "75f04293-f561-462f-9e74-a0d011e1594a"}

  @basic_tree %{"id" => "c5cc5c83-922b-428b-ad84-98a5c4da64e8",
      "question" => %{"en" => "Do you want to eat a main course or a dessert?",
        "es" => "Querés comer un primer plato o un postre?"},
      "responses" => [
        %{"keywords" => %{"en" => ["main course", "Main"],
           "es" => ["primer plato"]},
         "next" =>
           %{"id" => "c038e08e-6095-4897-9184-eae929aba8c6",
             "question" => %{"en" => "Are you a vegetarian?",
               "es" => "Sos vegetariano?"},
             "responses" => [%{"keywords" => %{"en" => ["yes "], "es" => [" si"]},
                "next" => %{"answer" => %{"en" => "Go with Risotto",
                    "es" => "Clavate un risotto"},
                    "id" => "9caa1ac7-1227-4b41-a303-4fa2f3085df8"}},
              %{"keywords" => %{"en" => ["no"], "es" => ["no"]},
                "next" => %{"answer" => %{"en" => "Go with barbecue",
                    "es" => "Comete un asado"},
                  "id" => "e530d33b-3720-4431-836a-662b26851424"}}]}},
       %{"keywords" => %{"en" => ["dessert"], "es" => ["postre"]},
         "next" => @basic_answer
        }
       ]}

  describe "flatten" do

    test "simple flatten" do
      flattened = DecisionTree.flatten(@basic_tree)

      assert Enum.count(flattened) == 5
      assert flattened[@basic_answer["id"]].id == @basic_answer["id"]

      is_vegetarian = flattened["c038e08e-6095-4897-9184-eae929aba8c6"].responses
        |> Enum.find(&(Enum.member?(Map.values(&1.keywords), ["yes"])))

      is_vegetarian_2 = flattened["c038e08e-6095-4897-9184-eae929aba8c6"].responses
        |> Enum.find(&(Enum.member?(Map.values(&1.keywords), ["si"])))

      assert is_vegetarian == is_vegetarian_2
      assert is_vegetarian.next == "9caa1ac7-1227-4b41-a303-4fa2f3085df8"
      assert flattened[is_vegetarian.next].message["en"] == "Go with Risotto"
    end

  end

  describe "parse" do

    test "parse question" do
      question = DecisionTree.parse_question(@basic_tree)

      assert question.id == "c5cc5c83-922b-428b-ad84-98a5c4da64e8"
      assert question.question == %{"en" => "Do you want to eat a main course or a dessert?", "es" => "Querés comer un primer plato o un postre?"}
      assert Enum.count(question.responses) == 2

      main_course = question.responses |> Enum.find(&(Enum.any?(Map.values(&1.keywords), fn(x) -> Enum.member?(x, "main course") end)))
      dessert = question.responses |> Enum.find(&(Enum.member?(Map.values(&1.keywords), ["dessert"])))

      assert main_course.next == "c038e08e-6095-4897-9184-eae929aba8c6"
      assert dessert.next == "75f04293-f561-462f-9e74-a0d011e1594a"
    end

    test "parse question stores responses in downcase" do
      question = DecisionTree.parse_question(@basic_tree)

      assert question.id == "c5cc5c83-922b-428b-ad84-98a5c4da64e8"
      assert question.question == %{"en" => "Do you want to eat a main course or a dessert?", "es" => "Querés comer un primer plato o un postre?"}
      assert Enum.count(question.responses) == 2

      main_course = question.responses |> Enum.find(&(Enum.any?(Map.values(&1.keywords), fn(x) -> Enum.member?(x, "main") end)))

      assert main_course.keywords["en"] == ["main course", "main"]
    end

    test "parse answer" do
      answer = DecisionTree.parse_answer(@basic_answer)

      assert answer.id == "75f04293-f561-462f-9e74-a0d011e1594a"
      assert Enum.member?(Map.values(answer.message), "Go with an ice cream")
      assert Enum.member?(Map.values(answer.message), "Comete un helado")
    end

  end

  describe "runtime" do
    setup do
      manifest = File.read!("test/fixtures/valid_manifest.json")
        |> Poison.decode!
        |> Map.put("languages", ["en"])

      {:ok, bot} = BotParser.parse(@bot_id, manifest)

      session = Session.new({@bot_id, "facebook", "1234567890/0987654321"})
        |> Session.save

      %{bot: bot, session: session}
    end

    test "starts the DecisionTree when the kewyord matches", %{bot: bot, session: session} do
      message = Message.new("meal recommendation", bot, session)
      message = Bot.chat(bot, message)

      assert message.reply == ["Do you want to eat a main course or a dessert?"]

      assert message.session |> Session.get(".decision_tree/2a516ba3-2e7b-48bf-b4c0-9b8cd55e003f") == %{"question" => "c5cc5c83-922b-428b-ad84-98a5c4da64e8"}
    end

    test "accepts an answer for the root question and performs the next", %{bot: bot, session: session} do
      message = Message.new("dessert", bot, session)
      message = message
        |> Message.put_session(".decision_tree/2a516ba3-2e7b-48bf-b4c0-9b8cd55e003f", %{"question" => "c5cc5c83-922b-428b-ad84-98a5c4da64e8"})
      message = Bot.chat(bot, message)

      assert message.reply == ["Are you vegan?"]
      assert message.session |> Session.get(".decision_tree/2a516ba3-2e7b-48bf-b4c0-9b8cd55e003f") == %{"question" => "42cc898f-42c3-4d39-84a3-651dbf7dfd5b"}
    end

    test "accepts an answer for the root question when there are different ways of selecting a branch (array) and performs the next", %{bot: bot, session: session} do
      message = Message.new("Main", bot, session)
      message = message
        |> Message.put_session(".decision_tree/2a516ba3-2e7b-48bf-b4c0-9b8cd55e003f", %{"question" => "c5cc5c83-922b-428b-ad84-98a5c4da64e8"})
      message = Bot.chat(bot, message)

      assert message.reply == ["Are you a vegetarian?"]
      assert message.session |> Session.get(".decision_tree/2a516ba3-2e7b-48bf-b4c0-9b8cd55e003f") == %{"question" => "c038e08e-6095-4897-9184-eae929aba8c6"}
    end

    test "when there is an invalid answer performs the last question again", %{bot: bot, session: session} do
      message = Message.new("i want dessert", bot, session)
      message = message
        |> Message.put_session(".decision_tree/2a516ba3-2e7b-48bf-b4c0-9b8cd55e003f", %{"question" => "42cc898f-42c3-4d39-84a3-651dbf7dfd5b"})
      message = Bot.chat(bot, message)

      assert message.reply == ["Are you vegan?"]
      assert message.session |> Session.get(".decision_tree/2a516ba3-2e7b-48bf-b4c0-9b8cd55e003f") == %{"question" => "42cc898f-42c3-4d39-84a3-651dbf7dfd5b"}
    end

    test "when it reaches an answer replies with it and resets the session", %{bot: bot, session: session} do
      message = Message.new("yes", bot, session)
      message = message
        |> Message.put_session(".decision_tree/2a516ba3-2e7b-48bf-b4c0-9b8cd55e003f", %{"question" => "42cc898f-42c3-4d39-84a3-651dbf7dfd5b"})
      message = Bot.chat(bot, message)

      assert message.reply == ["Go with a carrot cake"]
      assert message.session |> Session.get(".decision_tree/2a516ba3-2e7b-48bf-b4c0-9b8cd55e003f") == nil
    end
  end
end
