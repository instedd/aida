defmodule Aida.BotParserTest do
  use ExUnit.Case
  alias Aida.{Bot, BotParser, FrontDesk, Skill.KeywordResponder, Variable}

  @uuid "f905a698-310f-473f-b2d0-00d30ad58b0c"

  test "parse manifest" do
    manifest = File.read!("test/fixtures/valid_manifest.json") |> Poison.decode!
    bot = BotParser.parse(@uuid, manifest)

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
        %KeywordResponder{
          explanation: %{
            "en" => "I can give you information about our menu",
            "es" => "Te puedo dar información sobre nuestro menu"
          },
          clarification: %{
            "en" => "For menu options, write 'menu'",
            "es" => "Para información sobre nuestro menu, escribe 'menu'"
          },
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
      ]
    }
  end
end
