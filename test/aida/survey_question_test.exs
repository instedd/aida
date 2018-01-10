defmodule Aida.SurveyQuestionTest do
  alias Aida.{SelectQuestion, Choice, Session, Message, SurveyQuestion, InputQuestion, Bot}
  use ExUnit.Case

  @yes_no [
    %Choice{
      name: "yes",
      labels: %{
        "en" => ["Yes","Sure","Ok"],
        "es" => ["Si","OK","Dale"]
      }
    },
    %Choice{
      name: "no",
      labels: %{
        "en" => ["No","Nope","Later"],
        "es" => ["No","Luego","Nop"]
      }
    }
  ]

  @grapes [
    %Choice{
      name: "merlot",
      labels: %{
        "en" => ["merlot"],
        "es" => ["merlot"]
      }
    },
    %Choice{
      name: "syrah",
      labels: %{
        "en" => ["syrah"],
        "es" => ["syrah"]
      }
    },
    %Choice{
      name: "malbec",
      labels: %{
        "en" => ["malbec"],
        "es" => ["malbec"]
      }
    },
    %Choice{
      name: "cabernet sauvignon",
      labels: %{
        "en" => ["cabernet sauvignon"],
        "es" => ["cabernet sauvignon"]
      }
    }
  ]

  @entrees [
    %Choice{
      name: "spaghetti",
      labels: %{
        "en" => ["spaghetti"]
      },
      attributes: %{
        "food_type" => "pasta"
      }
    },
    %Choice{
      name: "lasagne",
      labels: %{
        "en" => ["lasagne"]
      },
      attributes: %{
        "food_type" => "pasta"
      }
    },
    %Choice{
      name: "hamburger",
      labels: %{
        "en" => ["hamburger"]
      },
      attributes: %{
        "food_type" => "meat"
      }
    },
    %Choice{
      name: "barbacue",
      labels: %{
        "en" => ["barbacue"]
      },
      attributes: %{
        "food_type" => "meat"
      }
    }
  ]

  @bot %Bot{}
  @session Session.new("1", %{"language" => "en"})
  @session_with_food_type Session.new("1", %{"language" => "en", "food_type" => "pasta"})

  describe "select_one" do
    test "valid_answer?" do
      question = %SelectQuestion{
        type: :select_one,
        choices: @yes_no,
        name: "smoker",
        message: %{
          "en" => "do you smoke?",
          "es" => "fumás?"
        }
      }

      message = Message.new("Yes", @bot, @session)
      assert SurveyQuestion.valid_answer?(question, message) == true

      message = Message.new("yes", @bot, @session)
      assert SurveyQuestion.valid_answer?(question, message) == true

      message = Message.new("foo", @bot, @session)
      assert SurveyQuestion.valid_answer?(question, message) == false
    end

    test "valid_answer? with choice filter" do
      question = %SelectQuestion{
        type: :select_one,
        choices: @entrees,
        name: "entree",
        message: %{"en" => "What do you want for dinner?"},
        choice_filter: Aida.Expr.parse("food_type = ${food_type}")
      }

      message = Message.new("spaghetti", @bot, @session_with_food_type)
      assert SurveyQuestion.valid_answer?(question, message) == true

      message = Message.new("hamburger", @bot, @session_with_food_type)
      assert SurveyQuestion.valid_answer?(question, message) == false

      message = Message.new("spaghetti", @bot, @session)
      assert SurveyQuestion.valid_answer?(question, message) == false
    end

    test "valid_answer? with choice filter but no attributes" do
      question = %SelectQuestion{
        type: :select_one,
        choices: @yes_no,
        name: "smoker",
        message: %{
          "en" => "do you smoke?",
          "es" => "fumás?"
        },
        choice_filter: Aida.Expr.parse("enabled = true()")
      }

      message = Message.new("yes", @bot, @session)
      assert SurveyQuestion.valid_answer?(question, message) == false
    end

    test "accept_answer" do
      question = %SelectQuestion{
        type: :select_one,
        choices: @yes_no,
        name: "smoker",
        message: %{
          "en" => "do you smoke?",
          "es" => "fumás?"
        }
      }

      message = Message.new("Yes", @bot, @session)
      assert SurveyQuestion.accept_answer(question, message) == {:ok, "yes"}

      message = Message.new("Sure", @bot, @session)
      assert SurveyQuestion.accept_answer(question, message) == {:ok, "yes"}

      message = Message.new("Ok", @bot, @session)
      assert SurveyQuestion.accept_answer(question, message) == {:ok, "yes"}

      message = Message.new("Nope", @bot, @session)
      assert SurveyQuestion.accept_answer(question, message) == {:ok, "no"}

      message = Message.new("foo", @bot, @session)
      assert SurveyQuestion.accept_answer(question, message) == :error
    end

    test "accept_answer with choice filter" do
      question = %SelectQuestion{
        type: :select_one,
        choices: @entrees,
        name: "entree",
        message: %{"en" => "What do you want for dinner?"},
        choice_filter: Aida.Expr.parse("food_type = ${food_type}")
      }

      message = Message.new("spaghetti", @bot, @session_with_food_type)
      assert SurveyQuestion.accept_answer(question, message) == {:ok, "spaghetti"}

      message = Message.new("hamburger", @bot, @session_with_food_type)
      assert SurveyQuestion.accept_answer(question, message) == :error
    end
  end

  describe "select_many" do
    test "valid_answer?" do
      question = %SelectQuestion{
        type: :select_many,
        choices: @grapes,
        name: "grape",
        message: %{
          "en" => "which wine do you prefer?",
          "es" => "qué vino te gusta?"
        }
      }

      message = Message.new("syrah, merlot", @bot, @session)
      assert SurveyQuestion.valid_answer?(question, message) == true

      message = Message.new("Cabernet sauvignon, Merlot", @bot, @session)
      assert SurveyQuestion.valid_answer?(question, message) == true

      message = Message.new("foo", @bot, @session)
      assert SurveyQuestion.valid_answer?(question, message) == false

      message = Message.new("foo, merlot", @bot, @session)
      assert SurveyQuestion.valid_answer?(question, message) == false

      message = Message.new("merlot, foo", @bot, @session)
      assert SurveyQuestion.valid_answer?(question, message) == false
    end

    test "valid_answer? with choice filter" do
      question = %SelectQuestion{
        type: :select_many,
        choices: @entrees,
        name: "entree",
        message: %{"en" => "What do you want for dinner?"},
        choice_filter: Aida.Expr.parse("food_type = ${food_type}")
      }

      message = Message.new("spaghetti, lasagne", @bot, @session_with_food_type)
      assert SurveyQuestion.valid_answer?(question, message) == true

      message = Message.new("spaghetti, hamburger", @bot, @session_with_food_type)
      assert SurveyQuestion.valid_answer?(question, message) == false
    end

    test "accept_answer" do
      question = %SelectQuestion{
        type: :select_many,
        choices: @grapes,
        name: "grape",
        message: %{
          "en" => "which wine do you prefer?",
          "es" => "qué vino te gusta?"
        }
      }

      message = Message.new("syrah, merlot", @bot, @session)
      assert SurveyQuestion.accept_answer(question, message) == {:ok, ["syrah", "merlot"]}

      message = Message.new("Cabernet Sauvignon, Merlot", @bot, @session)
      assert SurveyQuestion.accept_answer(question, message) == {:ok, ["cabernet sauvignon", "merlot"]}

      message = Message.new("foo", @bot, @session)
      assert SurveyQuestion.accept_answer(question, message) == :error

      message = Message.new("foo, merlot", @bot, @session)
      assert SurveyQuestion.accept_answer(question, message) == :error

      message = Message.new("merlot, foo", @bot, @session)
      assert SurveyQuestion.accept_answer(question, message) == :error
    end

    test "accept_answer with choice filter" do
      question = %SelectQuestion{
        type: :select_many,
        choices: @entrees,
        name: "entree",
        message: %{"en" => "What do you want for dinner?"},
        choice_filter: Aida.Expr.parse("food_type = ${food_type}")
      }

      message = Message.new("spaghetti, lasagne", @bot, @session_with_food_type)
      assert SurveyQuestion.accept_answer(question, message) == {:ok, ["spaghetti", "lasagne"]}

      message = Message.new("spaghetti, hamburger", @bot, @session_with_food_type)
      assert SurveyQuestion.accept_answer(question, message) == :error
    end
  end

  describe "integer" do
    test "valid_answer?" do
      question = %InputQuestion{
        type: :integer,
        name: "age",
        message: %{
          "en" => "How old are you?",
          "es" => "Cuántos años tenés?"
        }
      }

      message = Message.new("123456", @bot, @session)
      assert SurveyQuestion.valid_answer?(question, message) == true

      message = Message.new("1", @bot, @session)
      assert SurveyQuestion.valid_answer?(question, message) == true

      message = Message.new("-3", @bot, @session)
      assert SurveyQuestion.valid_answer?(question, message) == false

      message = Message.new("3a", @bot, @session)
      assert SurveyQuestion.valid_answer?(question, message) == false

      message = Message.new("foo", @bot, @session)
      assert SurveyQuestion.valid_answer?(question, message) == false

      message = Message.new("merlot, foo", @bot, @session)
      assert SurveyQuestion.valid_answer?(question, message) == false
    end

    test "accept_answer" do
      question = %InputQuestion{
        type: :integer,
        name: "age",
        message: %{
          "en" => "How old are you?",
          "es" => "Cuántos años tenés?"
        }
      }

      message = Message.new("123456", @bot, @session)
      assert SurveyQuestion.accept_answer(question, message) == {:ok, 123456}

      message = Message.new("1", @bot, @session)
      assert SurveyQuestion.accept_answer(question, message) == {:ok, 1}

      message = Message.new("-3", @bot, @session)
      assert SurveyQuestion.accept_answer(question, message) == :error
    end
  end

  describe "decimal" do
    test "valid_answer?" do
      question = %InputQuestion{
        type: :decimal,
        name: "age",
        message: %{
          "en" => "How old are you?",
          "es" => "Cuántos años tenés?"
        }
      }

      message = Message.new("123.456", @bot, @session)
      assert SurveyQuestion.valid_answer?(question, message) == true

      message = Message.new("1.2", @bot, @session)
      assert SurveyQuestion.valid_answer?(question, message) == true

      message = Message.new("-3.2", @bot, @session)
      assert SurveyQuestion.valid_answer?(question, message) == true

      message = Message.new("3", @bot, @session)
      assert SurveyQuestion.valid_answer?(question, message) == true

      message = Message.new("-3", @bot, @session)
      assert SurveyQuestion.valid_answer?(question, message) == true

      message = Message.new("0.1", @bot, @session)
      assert SurveyQuestion.valid_answer?(question, message) == true

      message = Message.new(".1", @bot, @session)
      assert SurveyQuestion.valid_answer?(question, message) == false

      message = Message.new("-3a", @bot, @session)
      assert SurveyQuestion.valid_answer?(question, message) == false

      message = Message.new("foo", @bot, @session)
      assert SurveyQuestion.valid_answer?(question, message) == false

      message = Message.new("merlot.foo", @bot, @session)
      assert SurveyQuestion.valid_answer?(question, message) == false
    end

    test "accept_answer" do
      question = %InputQuestion{
        type: :decimal,
        name: "age",
        message: %{
          "en" => "How old are you?",
          "es" => "Cuántos años tenés?"
        }
      }

      message = Message.new("123.456", @bot, @session)
      assert SurveyQuestion.accept_answer(question, message) == {:ok, 123.456}

      message = Message.new("1.2", @bot, @session)
      assert SurveyQuestion.accept_answer(question, message) == {:ok, 1.2}

      message = Message.new("-3.2", @bot, @session)
      assert SurveyQuestion.accept_answer(question, message) == {:ok, -3.2}

      message = Message.new("3", @bot, @session)
      assert SurveyQuestion.accept_answer(question, message) == {:ok, 3}

      message = Message.new("-3", @bot, @session)
      assert SurveyQuestion.accept_answer(question, message) == {:ok, -3}

      message = Message.new("0.1", @bot, @session)
      assert SurveyQuestion.accept_answer(question, message) == {:ok, 0.1}

      message = Message.new(".1", @bot, @session)
      assert SurveyQuestion.accept_answer(question, message) == :error

      message = Message.new("-3a", @bot, @session)
      assert SurveyQuestion.accept_answer(question, message) == :error

      message = Message.new("foo", @bot, @session)
      assert SurveyQuestion.accept_answer(question, message) == :error

      message = Message.new("merlot.foo", @bot, @session)
      assert SurveyQuestion.accept_answer(question, message) == :error
    end
  end

  describe "text" do
    test "valid_answer?" do
      question = %InputQuestion{
        type: :text,
        name: "age",
        message: %{
          "en" => "What's your name?",
          "es" => "Cómo te llamás?"
        }
      }

      message = Message.new("lalala llala", @bot, @session)
      assert SurveyQuestion.valid_answer?(question, message) == true

      message = Message.new(" ", @bot, @session)
      assert SurveyQuestion.valid_answer?(question, message) == false
    end

    test "accept_answer" do
      question = %InputQuestion{
        type: :text,
        name: "age",
        message: %{
          "en" => "What's your name?",
          "es" => "Cómo te llamás?"
        }
      }

      message = Message.new("lalala llala", @bot, @session)
      assert SurveyQuestion.accept_answer(question, message) == {:ok, "lalala llala"}

      message = Message.new(" ", @bot, @session)
      assert SurveyQuestion.accept_answer(question, message) == :error
    end
  end
end
