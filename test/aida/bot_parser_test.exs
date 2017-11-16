defmodule Aida.BotParserTest do
  use ExUnit.Case
  alias Aida.{Bot, BotParser, FrontDesk, Skill.KeywordResponder, Variable}
  alias Aida.Channel.Facebook

  @uuid "f905a698-310f-473f-b2d0-00d30ad58b0c"

  test "parse valid manifest" do
    manifest = File.read!("test/fixtures/valid_manifest.json") |> Poison.decode!
    {:ok, bot} = BotParser.parse(@uuid, manifest)

    assert bot == %Bot{
      id: @uuid,
      languages: ["en", "es"],
      front_desk: %FrontDesk{
        threshold: 0.7,
        greeting: %{
          "en" => "Hello, I'm a Restaurant bot",
          "es" => "Hola, soy un bot de Restaurant"
        },
        introduction: %{
          "en" => "I can do a number of things",
          "es" => "Puedo ayudarte con varias cosas"
        },
        not_understood: %{
          "en" => "Sorry, I didn't understand that",
          "es" => "Perdón, no entendí lo que dijiste"
        },
        clarification: %{
          "en" => "I'm not sure exactly what you need.",
          "es" => "Perdón, no estoy seguro de lo que necesitás."
        }
      },
      skills: [
        %Aida.Skill.LanguageDetector{
          explanation: "To chat in english say 'english' or 'inglés'. Para hablar en español escribe 'español' o 'spanish'",
          languages: %{
            "en" => ["english", "inglés"],
            "es" => ["español", "spanish"]
          }
        },
        %KeywordResponder{
          explanation: %{
            "en" => "I can give you information about our menu",
            "es" => "Te puedo dar información sobre nuestro menu"
          },
          clarification: %{
            "en" => "For menu options, write 'menu'",
            "es" => "Para información sobre nuestro menu, escribe 'menu'"
          },
          id: "this is a string id",
          name: "Food menu",
          keywords: %{
            "en" => ["menu", "food"],
            "es" => ["menu", "comida"]
          },
          response: %{
            "en" => "We have {food_options}",
            "es" => "Tenemos {food_options}"
          }
        },
        %KeywordResponder{
          explanation: %{
            "en" => "I can give you information about our opening hours",
            "es" => "Te puedo dar información sobre nuestro horario"
          },
          clarification: %{
            "en" => "For opening hours say 'hours'",
            "es" => "Para información sobre nuestro horario escribe 'horario'"
          },
          id: "this is a different id",
          name: "Opening hours",
          keywords: %{
            "en" => ["hours","time"],
            "es" => ["horario","hora"]
          },
          response: %{
            "en" => "We are open every day from 7pm to 11pm",
            "es" => "Abrimos todas las noches de 19 a 23"
          }
        }
      ],
      variables: [
        %Variable{
          name: "food_options",
          values: %{
            "en" => "barbecue and pasta",
            "es" => "parrilla y pasta"
          }
        }
      ],
      channels: [
        %Facebook{
          bot_id: @uuid,
          page_id: "1234567890",
          verify_token: "qwertyuiopasdfghjklzxcvbnm",
          access_token: "QWERTYUIOPASDFGHJKLZXCVBNM"
        }
      ]
    }
  end

  test "parse manifest with duplicated skill id" do
    manifest = File.read!("test/fixtures/valid_manifest.json") |> Poison.decode!

    manifest = manifest
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

    assert {:error, "Duplicated skill (this is the same id)"} == BotParser.parse(@uuid, manifest)
  end

  test "parse manifest with duplicated language_detector" do
    manifest = File.read!("test/fixtures/valid_manifest.json") |> Poison.decode!

    manifest = manifest
        |> Map.put("skills", [
          %{
            "type" => "language_detector",
            "explanation" => "To chat in english say 'english' or 'inglés'. Para hablar en español escribe 'español' o 'spanish'",
            "languages" => %{
              "en" => ["english", "inglés"],
              "es" => ["español", "spanish"]
            }
          },
          %{
            "type" => "language_detector",
            "explanation" => "To chat in english say 'english' or 'inglés'. Para hablar en español escribe 'español' o 'spanish'",
            "languages" => %{
              "en" => ["english", "inglés"],
              "es" => ["español", "spanish"]
            }
          }
        ])

    assert {:error, "Duplicated skill (language_detector)"} == BotParser.parse(@uuid, manifest)
  end

end
