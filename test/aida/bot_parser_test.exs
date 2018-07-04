defmodule Aida.BotParserTest do
  use ExUnit.Case
  alias Aida.{
    Bot,
    BotParser,
    DataTable,
    FrontDesk,
    Skill.KeywordResponder,
    Skill.LanguageDetector,
    Skill.ScheduledMessages,
    Skill.ScheduledMessages.DelayedMessage,
    Skill.ScheduledMessages.FixedTimeMessage,
    Skill.ScheduledMessages.RecurrentMessage,
    Skill.Survey,
    Skill.Survey.SelectQuestion,
    Skill.Survey.InputQuestion,
    Skill.Survey.Choice,
    Skill.DecisionTree,
    Variable,
    Recurrence,
    Unsubscribe
  }
  alias Aida.Channel.{Facebook, WebSocket}

  @uuid "f905a698-310f-473f-b2d0-00d30ad58b0c"

  test "parse valid manifest" do
    manifest = File.read!("test/fixtures/valid_manifest.json") |> Poison.decode!
    {:ok, bot} = BotParser.parse(@uuid, manifest)

    assert bot == %Bot{
      id: @uuid,
      languages: ["en", "es"],
      front_desk: %FrontDesk{
        threshold: 0.3,
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
        },
        unsubscribe: %Unsubscribe{
          introduction_message: %{
            "en" => "Send UNSUBSCRIBE to stop receiving messages",
            "es" => "Enviá DESUSCRIBIR para dejar de recibir mensajes"
          },
          keywords: %{
            "en" => ["unsubscribe"],
            "es" => ["desuscribir"]
          },
          acknowledge_message: %{
            "en" => "I won't send you any further messages",
            "es" => "No te enviaré más mensajes"
          }
        }
      },
      skills: [
        %LanguageDetector{
          explanation: "To chat in english say 'english' or 'inglés'. Para hablar en español escribe 'español' o 'spanish'",
          bot_id: @uuid,
          languages: %{
            "en" => ["english", "inglés"],
            "es" => ["español", "spanish"]
          },
          reply_to_unsupported_language: true
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
          bot_id: @uuid,
          name: "Food menu",
          keywords: %{
            "en" => ["menu", "food"],
            "es" => ["menu", "comida"]
          },
          response: %{
            "en" => "We have ${food_options}",
            "es" => "Tenemos ${food_options}"
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
          bot_id: @uuid,
          name: "Opening hours",
          keywords: %{
            "en" => ["hours","time"],
            "es" => ["horario","hora"]
          },
          response: %{
            "en" => "We are open every day from 7pm to 11pm",
            "es" => "Abrimos todas las noches de 19 a 23"
          }
        },
        %ScheduledMessages{
          id: "inactivity_check",
          bot_id: @uuid,
          name: "Inactivity Check",
          schedule_type: :since_last_incoming_message,
          messages: [
            %DelayedMessage{
              delay: 1440,
              message: %{
                "en" => "Hey, I didn’t hear from you for the last day, is there anything I can help you with?",
                "es" => "Hola! Desde ayer que no sé nada de vos, ¿puedo ayudarte en algo?"
              }
            },
            %DelayedMessage{
              delay: 2880,
              message: %{
                "en" => "Hey, I didn’t hear from you for the last 2 days, is there anything I can help you with?",
                "es" => "Hola! Hace 2 días que no sé nada de vos, ¿puedo ayudarte en algo?"
              }
            },
            %DelayedMessage{
              delay: 43200,
              message: %{
                "en" => "Hey, I didn’t hear from you for the last month, is there anything I can help you with?",
                "es" => "Hola! Hace un mes que no sé nada de vos, ¿puedo ayudarte en algo?"
              }
            }
          ]
        },
        %ScheduledMessages{
          id: "happy_new_year",
          bot_id: @uuid,
          name: "Happy New Year",
          schedule_type: :fixed_time,
          messages: [
            %FixedTimeMessage{
              schedule: ~N[2018-01-01 00:00:00] |> DateTime.from_naive!("Etc/UTC"),
              message: %{
                "en" => "Happy new year!",
                "es" => "Feliz año nuevo!"
              }
            }
          ]
        },
        %ScheduledMessages{
          id: "reminders",
          bot_id: @uuid,
          name: "Reminders",
          schedule_type: :recurrent,
          messages: [
            %RecurrentMessage{
              recurrence: %Recurrence.Daily{start: ~N[2018-01-01T10:00:00Z] |> DateTime.from_naive!("Etc/UTC"), every: 7},
              message: %{
                "en" => "Remember we're closed on Mondays",
                "es" => "Recuerde que no abrimos los lunes"
              }
            },
            %RecurrentMessage{
              recurrence: %Recurrence.Weekly{start: ~N[2018-01-01T11:00:00Z] |> DateTime.from_naive!("Etc/UTC"), every: 1, on: [:saturday, :sunday]},
              message: %{
                "en" => "Discover our weekend specialities",
                "es" => "Descubra nuestras especialidades del fin de semana"
              }
            },
            %RecurrentMessage{
              recurrence: %Recurrence.Monthly{start: ~N[2018-01-01T12:00:00Z] |> DateTime.from_naive!("Etc/UTC"), every: 2, each: 5},
              message: %{
                "en" => "We change the menu every two months. Say 'menu' to discover it!",
                "es" => "Cambiamos el menú cada dos meses. Diga 'menu' para descrubrirlo!"
              }
            }
          ]
        },
        %Survey{
          id: "food_preferences",
          bot_id: @uuid,
          name: "Food Preferences",
          schedule: nil,
          keywords: %{"en" => ["food preferences", "food survey", "survey"], "es" => ["preferencias alimentarias", "encuesta alimentaria"]},
          questions: [
            %Aida.Skill.Survey.Note{
              type: :note,
              name: "introduction",
              message: %{
                "en" => "I would like to ask you a few questions to better cater for your food preferences.",
                "es" => "Me gustaría hacerte algunas preguntas para poder adecuarnos mejor a tus preferencias de comida."
              }
            },
            %SelectQuestion{
              name: "opt_in",
              type: :select_one,
              choices: [
                %Choice{
                  name: "yes",
                  labels: %{
                    "en" => ["yes", "sure", "ok"],
                    "es" => ["si", "ok", "dale"]
                  }
                },
                %Choice{
                  name: "no",
                  labels: %{
                    "en" => ["no", "nope", "later"],
                    "es" => ["no", "luego", "nop"]
                  }
                }
              ],
              message: %{
                "en" => "May I ask you now?",
                "es" => "Puedo preguntarte ahora?"
              }
            },
            %InputQuestion{
              name: "age",
              type: :integer,
              message: %{
                "en" => "How old are you?",
                "es" => "Qué edad tenés?"
              }
            },
            %InputQuestion{
              name: "wine_temp",
              type: :decimal,
              relevant: Aida.Expr.parse("${age} >= 18"),
              constraint: Aida.Expr.parse(". < 100"),
              constraint_message: %{
                "en" => "Invalid temperature",
                "es" => "Temperatura inválida"
              },
              message: %{
                "en" => "At what temperature do your like red wine the best?",
                "es" => "A qué temperatura preferís tomar el vino tinto?"
              }
            },
            %SelectQuestion{
              name: "wine_grapes",
              type: :select_many,
              relevant: Aida.Expr.parse("${age} >= 18"),
              choices: [
                %Choice{
                  name: "merlot",
                  labels: %{
                    "en" => ["merlot"],
                    "es" => ["merlot"]
                  },
                  attributes: %{
                    "type" => "red"
                  }
                },
                %Choice{
                  name: "syrah",
                  labels: %{
                    "en" => ["syrah"],
                    "es" => ["syrah"]
                  },
                  attributes: %{
                    "type" => "red"
                  }
                },
                %Choice{
                  name: "malbec",
                  labels: %{
                    "en" => ["malbec"],
                    "es" => ["malbec"]
                  },
                  attributes: %{
                    "type" => "red"
                  }
                },
                %Choice{
                  name: "chardonnay",
                  labels: %{
                    "en" => ["chardonnay"],
                    "es" => ["chardonnay"]
                  },
                  attributes: %{
                    "type" => "white"
                  }
                }
              ],
              message: %{
                "en" => "What are your favorite wine grapes?",
                "es" => "Que variedades de vino preferís?"
              },
              constraint_message: %{
                "en" => "I don't know that wine",
                "es" => "No conozco ese vino"
              },
              choice_filter: Aida.Expr.parse("type = 'red' or type = 'white'")
            },
            %InputQuestion{
              name: "picture",
              type: :image,
              message: %{
                "en" => "Can we see your home?",
                "es" => "Podemos ver tu casa?"
              }
            },
            %Aida.Skill.Survey.Note{
              type: :note,
              name: "nice",
              message: %{"en" => "Nice!", "es" => "Muy linda!"}
            },
            %InputQuestion{
              name: "request",
              type: :text,
              message: %{
                "en" => "Any particular requests for your dinner?",
                "es" => "Algún pedido especial para tu cena?"
              }
            },
            %Aida.Skill.Survey.Note{
              type: :note,
              name: "thanks",
              message: %{"en" => "Thank you!", "es" => "Gracias!"}
            }
          ]
        },
        %DecisionTree{
          bot_id: "f905a698-310f-473f-b2d0-00d30ad58b0c",
          id: "2a516ba3-2e7b-48bf-b4c0-9b8cd55e003f",
          root_id: "c5cc5c83-922b-428b-ad84-98a5c4da64e8",
          keywords: %{"en" => ["meal recommendation", "recommendation"], "es" => ["recomendación", "recomendacion"]},
          clarification: %{
            "en" => "To get a meal recommendation write 'meal recommendation'",
            "es" => "Para recibir una recomendación escribe 'recomendación'"
          },
          explanation: %{
            "en" => "I can help you choose a meal that fits your dietary restrictions",
            "es" => "Te puedo ayudar a elegir una comida que se adapte a tus restricciones alimentarias"
          },
          name: "Food menu",
          relevant: nil,
          tree: %{
            "031d9a25-f457-4b21-b83b-13e00ece6cc0" =>
              %Aida.Skill.DecisionTree.Answer{
                id: "031d9a25-f457-4b21-b83b-13e00ece6cc0",
                message: %{"en" => "Go with Risotto", "es" => "Clavate un risotto"}
              },
            "3d5d6819-ae31-45b6-b8f6-13d62b092730" =>
              %Aida.Skill.DecisionTree.Answer{
                id: "3d5d6819-ae31-45b6-b8f6-13d62b092730",
                message: %{"en" => "Go with a carrot cake", "es" => "Come una torta de zanahoria"}
              },
            "42cc898f-42c3-4d39-84a3-651dbf7dfd5b" =>
              %Aida.Skill.DecisionTree.Question{
                id: "42cc898f-42c3-4d39-84a3-651dbf7dfd5b",
                question: %{"en" => "Are you vegan?", "es" => "Sos vegano?"},
                responses: [
                  %Aida.Skill.DecisionTree.Response{
                    keywords: %{"en" => ["yes"], "es" => ["si"]},
                    next: "3d5d6819-ae31-45b6-b8f6-13d62b092730"
                  },
                  %Aida.Skill.DecisionTree.Response{
                    keywords: %{"en" => ["no"], "es" => ["no"]},
                    next: "5d79bf1c-4863-401f-8f08-89ffb3af33cf"
                  }
                ]
              },
            "5d79bf1c-4863-401f-8f08-89ffb3af33cf" =>
              %Aida.Skill.DecisionTree.Question{
                id: "5d79bf1c-4863-401f-8f08-89ffb3af33cf",
                question: %{"en" => "Are you lactose intolerant?", "es" => "Sos intolerante a la lactosa?"},
                responses: [
                  %Aida.Skill.DecisionTree.Response{
                    keywords: %{"en" => ["yes"], "es" => ["si"]},
                    next: "f00f115f-4a0b-45e1-a123-ac1756616be7"
                  },
                  %Aida.Skill.DecisionTree.Response{
                    keywords: %{"en" => ["no"], "es" => ["no"]},
                    next: "75f04293-f561-462f-9e74-a0d011e1594a"
                  }
                ]
              },
            "75f04293-f561-462f-9e74-a0d011e1594a" =>
              %Aida.Skill.DecisionTree.Answer{
                id: "75f04293-f561-462f-9e74-a0d011e1594a",
                message: %{"en" => "Go with an ice cream", "es" => "Comete un helado"}
              },
            "c038e08e-6095-4897-9184-eae929aba8c6" =>
              %Aida.Skill.DecisionTree.Question{
                id: "c038e08e-6095-4897-9184-eae929aba8c6",
                question: %{"en" => "Are you a vegetarian?", "es" => "Sos vegetariano?"},
                responses: [
                  %Aida.Skill.DecisionTree.Response{
                    keywords: %{"en" => ["yes"], "es" => ["si"]},
                    next: "031d9a25-f457-4b21-b83b-13e00ece6cc0"
                  },
                  %Aida.Skill.DecisionTree.Response{
                    keywords: %{"en" => ["no"], "es" => ["no"]},
                    next: "e530d33b-3720-4431-836a-662b26851424"
                  }
                ]
              },
            "e530d33b-3720-4431-836a-662b26851424" =>
              %Aida.Skill.DecisionTree.Answer{
                id: "e530d33b-3720-4431-836a-662b26851424",
                message: %{"en" => "Go with barbecue", "es" => "Comete un asado"}
              },
            "f00f115f-4a0b-45e1-a123-ac1756616be7" =>
              %Aida.Skill.DecisionTree.Answer{
                id: "f00f115f-4a0b-45e1-a123-ac1756616be7",
                message: %{"en" => "Go with a chocolate mousse", "es" => "Comete una mousse de chocolate"}
              },
            "c5cc5c83-922b-428b-ad84-98a5c4da64e8" =>
              %Aida.Skill.DecisionTree.Question{
                id: "c5cc5c83-922b-428b-ad84-98a5c4da64e8",
                question: %{"en" => "Do you want to eat a main course or a dessert?", "es" => "Querés comer un primer plato o un postre?"},
                responses: [
                  %Aida.Skill.DecisionTree.Response{
                    keywords: %{"en" => ["main course", "main"], "es" => ["primer plato"]},
                    next: "c038e08e-6095-4897-9184-eae929aba8c6"
                  },
                  %Aida.Skill.DecisionTree.Response{
                    keywords: %{"en" => ["dessert"], "es" => ["postre"]},
                    next: "42cc898f-42c3-4d39-84a3-651dbf7dfd5b"
                  }
                ]
              }
          }
        }
      ],
      variables: [
        %Variable{
          name: "food_options",
          values: %{
            "en" => "barbecue and pasta",
            "es" => "parrilla y pasta"
          },
          overrides: [
            %Variable.Override{
              relevant: Aida.Expr.parse("${age} > 18"),
              values: %{
                "en" => "barbecue and pasta and a exclusive selection of wines",
                "es" => "parrilla y pasta además de nuestra exclusiva selección de vinos"
              }
            }
          ]
        },
        %Variable{
          name: "title",
          values: %{
            "en" => "",
            "es" => ""
          },
          overrides: [
            %Variable.Override{
              relevant: Aida.Expr.parse("${gender} = 'male'"),
              values: %{
                "en" => "Mr.",
                "es" => "Sr."
              }
            },
            %Variable.Override{
              relevant: Aida.Expr.parse("${gender} = 'female'"),
              values: %{
                "en" => "Ms.",
                "es" => "Sra."
              }
            }
          ]
        },
        %Variable{
          name: "full_name",
          values: %{
            "en" => "${title} ${first_name} ${last_name}",
            "es" => "${title} ${first_name} ${last_name}"
          }
        }
      ],
      channels: [
        %Facebook{
          bot_id: @uuid,
          page_id: "1234567890",
          verify_token: "qwertyuiopasdfghjklzxcvbnm",
          access_token: "QWERTYUIOPASDFGHJKLZXCVBNM"
        },
        %WebSocket{
          bot_id: @uuid,
          access_token: "qwertyuiopasdfghjklzxcvbnm"
        }
      ],
      public_keys: [
        <<192, 32, 220, 251, 28, 138, 201, 29, 249, 12, 21, 61, 34, 29, 181, 159, 252, 140, 39, 245, 170, 188, 103, 0, 99, 223, 111, 214, 76, 205, 17, 108>>,
        <<197, 168, 21, 78, 100, 176, 99, 198, 117, 156, 125, 25, 91, 176, 1, 205, 25, 69, 117, 188, 60, 189, 159, 3, 207, 97, 74, 124, 91, 160, 148, 34>>
      ],
      data_tables: [
        %DataTable{
          name: "Distribution_days",
          columns: ["Location", "Day", "Distribution_place", "# of distribution posts"],
          data: [
            ["Kakuma 1", "Next Thursday", "In front of the square", 2],
            ["Kakuma 2", "Next Friday", "In front of the church", 1],
            ["Kakuma 3", "Next Saturday", "In front of the distribution centre", 3]
          ]
        }
      ]
    }
  end

  test "parse valid manifest with skill relevances" do
    manifest = File.read!("test/fixtures/valid_manifest_with_skill_relevances.json") |> Poison.decode!
    {:ok, bot} = BotParser.parse(@uuid, manifest)

    assert bot == %Bot{
      id: @uuid,
      languages: ["en", "es"],
      front_desk: %FrontDesk{
        threshold: 0.3,
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
        },
        unsubscribe: %Unsubscribe{
          introduction_message: %{
            "en" => "Send UNSUBSCRIBE to stop receiving messages",
            "es" => "Enviá DESUSCRIBIR para dejar de recibir mensajes"
          },
          keywords: %{
            "en" => ["unsubscribe"],
            "es" => ["desuscribir"]
          },
          acknowledge_message: %{
            "en" => "I won't send you any further messages",
            "es" => "No te enviaré más mensajes"
          }
        }
      },
      skills: [
        %LanguageDetector{
          explanation: "To chat in english say 'english' or 'inglés'. Para hablar en español escribe 'español' o 'spanish'",
          bot_id: @uuid,
          languages: %{
            "en" => ["english", "inglés"],
            "es" => ["español", "spanish"]
          },
          reply_to_unsupported_language: false
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
          id: "food_menu",
          bot_id: @uuid,
          name: "Food menu",
          keywords: %{
            "en" => ["menu", "food"],
            "es" => ["menu", "comida"]
          },
          response: %{
            "en" => "We have {food_options}",
            "es" => "Tenemos {food_options}"
          },
          relevant: Aida.Expr.parse("${age} > 18")
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
          id: "opening_hours",
          bot_id: @uuid,
          name: "Opening hours",
          keywords: %{
            "en" => ["hours","time"],
            "es" => ["horario","hora"]
          },
          response: %{
            "en" => "We are open every day from 7pm to 11pm",
            "es" => "Abrimos todas las noches de 19 a 23"
          }
        },
        %ScheduledMessages{
          id: "inactivity_check",
          bot_id: @uuid,
          name: "Inactivity Check",
          schedule_type: :since_last_incoming_message,
          relevant: Aida.Expr.parse("${opt_in} = true()"),
          messages: [
            %DelayedMessage{
              delay: 1440,
              message: %{
                "en" => "Hey, I didn’t hear from you for the last day, is there anything I can help you with?",
                "es" => "Hola! Desde ayer que no sé nada de vos, ¿puedo ayudarte en algo?"
              }
            },
            %DelayedMessage{
              delay: 2880,
              message: %{
                "en" => "Hey, I didn’t hear from you for the last 2 days, is there anything I can help you with?",
                "es" => "Hola! Hace 2 días que no sé nada de vos, ¿puedo ayudarte en algo?"
              }
            },
            %DelayedMessage{
              delay: 43200,
              message: %{
                "en" => "Hey, I didn’t hear from you for the last month, is there anything I can help you with?",
                "es" => "Hola! Hace un mes que no sé nada de vos, ¿puedo ayudarte en algo?"
              }
            }
          ]
        },
        %Survey{
          id: "food_preferences",
          bot_id: @uuid,
          name: "Food Preferences",
          schedule: ~N[2117-12-10 01:40:13] |> DateTime.from_naive!("Etc/UTC"),
          relevant: Aida.Expr.parse("${opt_in} != false()"),
          keywords: nil,
          questions: [
            %SelectQuestion{
              name: "opt_in",
              type: :select_one,
              choices: [
                %Choice{
                  name: "yes",
                  labels: %{
                    "en" => ["yes", "sure", "ok"],
                    "es" => ["si", "ok", "dale"]
                  }
                },
                %Choice{
                  name: "no",
                  labels: %{
                    "en" => ["no", "nope", "later"],
                    "es" => ["no", "luego", "nop"]
                  }
                }
              ],
              message: %{
                "en" => "I would like to ask you a few questions to better cater for your food preferences. Is that ok?",
                "es" => "Me gustaría hacerte algunas preguntas para poder adecuarnos mejor a tus preferencias de comida. Puede ser?"
              }
            },
            %InputQuestion{
              name: "age",
              type: :integer,
              message: %{
                "en" => "How old are you?",
                "es" => "Qué edad tenés?"
              }
            },
            %InputQuestion{
              name: "wine_temp",
              type: :decimal,
              relevant: Aida.Expr.parse("${age} >= 18"),
              constraint: Aida.Expr.parse(". < 100"),
              constraint_message: %{
                "en" => "Invalid temperature",
                "es" => "Temperatura inválida"
              },
              message: %{
                "en" => "At what temperature do your like red wine the best?",
                "es" => "A qué temperatura preferís tomar el vino tinto?"
                }
              },
            %SelectQuestion{
              name: "wine_grapes",
              type: :select_many,
              relevant: Aida.Expr.parse("${age} >= 18"),
              choices: [
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
                }
              ],
              message: %{
                "en" => "What are your favorite wine grapes?",
                "es" => "Que variedades de vino preferís?"
              },
              constraint_message: %{
                "en" => "I don't know that wine",
                "es" => "No conozco ese vino"
              }
            },
            %InputQuestion{
              name: "request",
              type: :text,
              message: %{
                "en" => "Any particular requests for your dinner?",
                "es" => "Algún pedido especial para tu cena?"
              }
            }
          ]
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
        },
        %WebSocket{
          bot_id: @uuid,
          access_token: "qwertyuiopasdfghjklzxcvbnm"
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

  test "parse manifest with invalid expression" do
    manifest = File.read!("test/fixtures/valid_manifest.json") |> Poison.decode!
      |> Map.put("skills", [
        %{
            "type" => "keyword_responder",
            "id" => "this is the same id",
            "name" => "Food menu",
            "relevant" => "${foo} < ...",
            "explanation" => %{
              "en" => "I can give you information about our menu"
            },
            "clarification" => %{
              "en" => "For menu options, write 'menu'"
            },
            "keywords" => %{
              "en" => ["menu","food"]
            },
            "response" => %{
              "en" => "We have ${food_options}"
            }
          }
      ])

    assert {:error, "Invalid expression: '${foo} < ...'"} == BotParser.parse(@uuid, manifest)
  end

  describe "encryption" do
    setup :encrypted_survey

    test "parse manifest with encrypted questions in survey", %{manifest: manifest} do
      {:ok, bot} = BotParser.parse(@uuid, manifest)

      questions = (bot.skills |> hd).questions
      find_by_name = fn(questions, name) -> Enum.filter(questions, &(&1.name == name)) |> hd end

      assert find_by_name.(questions, "opt_in").encrypt != nil
      refute find_by_name.(questions, "opt_in").encrypt

      assert find_by_name.(questions, "request").encrypt != nil
      refute find_by_name.(questions, "request").encrypt

      assert find_by_name.(questions, "age").encrypt

      assert find_by_name.(questions, "wine_grapes").encrypt
    end

    test "raise when parsing manifest with encrypted questions in survey and no public_keys", %{manifest: manifest} do

      manifest = manifest |> Map.put("public_keys", [])

      assert {:error, "Missing public_keys in manifest"} = BotParser.parse(@uuid, manifest)
    end
  end

  defp encrypted_survey(_context) do
    manifest =
      File.read!("test/fixtures/valid_manifest.json") |> Poison.decode!()
      |> Map.put("skills", [
        %{
          "type" => "survey",
          "id" => "food_preferences",
          "name" => "Food Preferences",
          "schedule" => "2117-12-10T01:40:13Z",
          "questions" => [
            %{
              "type" => "select_one",
              "choices" => "yes_no",
              "name" => "opt_in",
              "message" => %{
                "en" =>
                  "I would like to ask you a few questions to better cater for your food preferences. Is that ok?",
                "es" =>
                  "Me gustaría hacerte algunas preguntas para poder adecuarnos mejor a tus preferencias de comida. Puede ser?"
              }
            },
            %{
              "type" => "integer",
              "name" => "age",
              "encrypt" => true,
              "message" => %{
                "en" => "How old are you?",
                "es" => "Qué edad tenés?"
              }
            },
            %{
              "type" => "select_many",
              "name" => "wine_grapes",
              "encrypt" => true,
              "relevant" => "${age} >= 18",
              "choices" => "grapes",
              "message" => %{
                "en" => "What are your favorite wine grapes?",
                "es" => "Que variedades de vino preferís?"
              }
            },
            %{
              "type" => "text",
              "name" => "request",
              "message" => %{
                "en" => "Any particular requests for your dinner?",
                "es" => "Algún pedido especial para tu cena?"
              }
            }
          ],
          "choice_lists" => [
            %{
              "name" => "yes_no",
              "choices" => [
                %{
                  "name" => "yes",
                  "labels" => %{
                    "en" => ["yes", "sure", "ok"],
                    "es" => ["si", "ok", "dale"]
                  }
                },
                %{
                  "name" => "no",
                  "labels" => %{
                    "en" => ["no", "nope", "later"],
                    "es" => ["no", "luego", "nop"]
                  }
                }
              ]
            },
            %{
              "name" => "grapes",
              "choices" => [
                %{
                  "name" => "merlot",
                  "labels" => %{
                    "en" => ["merlot"],
                    "es" => ["merlot"]
                  },
                  attributes: %{
                    "type" => "red"
                  }
                },
                %{
                  "name" => "syrah",
                  "labels" => %{
                    "en" => ["syrah"],
                    "es" => ["syrah"]
                  },
                  "attributes" => %{
                    "type" => "red"
                  }
                }
              ]
            }
          ]
        }
      ])

    [manifest: manifest]
  end
end
