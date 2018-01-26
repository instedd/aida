defmodule Aida.DecisionTreeTest do
  alias Aida.Skill.DecisionTree
  use Aida.DataCase

  @bot_id "c4cf6a74-d154-4e2f-9945-ba999b06f8bd"
  @skill_id "e7f2702c-5188-4d12-97b7-274162509ed1"
  @session_id "#{@bot_id}/facebook/1234567890/0987654321"

  @basic_answer %{"answer" =>
                  %{"en" => "Go with an ice cream",
                    "es" => "Comete un helado"},
                "id" => "75f04293-f561-462f-9e74-a0d011e1594a"}

  @basic_tree %{"id" => "c5cc5c83-922b-428b-ad84-98a5c4da64e8",
      "question" => %{"en" => "Do you want to eat a main course or a dessert?",
        "es" => "Querés comer un primer plato o un postre?"},
      "responses" => [
        %{"keywords" => %{"en" => ["main course"],
           "es" => ["primer plato"]},
         "next" =>
           %{"id" => "c038e08e-6095-4897-9184-eae929aba8c6",
             "question" => %{"en" => "Are you a vegetarian?",
               "es" => "Sos vegetariano?"},
             "responses" => [%{"keywords" => %{"en" => ["yes"], "es" => ["si"]},
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

      assert flattened["root"].id == "c5cc5c83-922b-428b-ad84-98a5c4da64e8"
      assert Enum.count(flattened) == 5
      assert flattened[@basic_answer["id"]].id == @basic_answer["id"]

      is_vegetarian = flattened["c038e08e-6095-4897-9184-eae929aba8c6"].responses
        |> Enum.find(&(Enum.member?(Map.values(&1.keywords), ["yes"])))

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

      main_course = question.responses |> Enum.find(&(Enum.member?(Map.values(&1.keywords), ["main course"])))
      dessert = question.responses |> Enum.find(&(Enum.member?(Map.values(&1.keywords), ["dessert"])))

      assert main_course.next == "c038e08e-6095-4897-9184-eae929aba8c6"
      assert dessert.next == "75f04293-f561-462f-9e74-a0d011e1594a"
    end

    test "parse answer" do
      answer = DecisionTree.parse_answer(@basic_answer)

      assert answer.id == "75f04293-f561-462f-9e74-a0d011e1594a"
      assert Enum.member?(Map.values(answer.message), "Go with an ice cream")
      assert Enum.member?(Map.values(answer.message), "Comete un helado")
    end

  end
end
