defmodule Aida.JsonSchemaTest do
  use ExUnit.Case

  alias Aida.JsonSchema

  setup_all do
    GenServer.start_link(JsonSchema, [], name: JsonSchema.server_ref)
    :ok
  end

  @valid_base_64_key ~s("ZWNjYzIwNGMtYmExNS00Y2M5LWI5YTMtMjJiOTg0ZDc5YThl")
  @invalid_base_64_key ".."
  @valid_localized_string ~s({"en": "a"})
  @valid_empty_localized_string ~s({"en": "a"})
  @valid_message ~s({"message" : #{@valid_localized_string}})
  @valid_front_desk ~s({
    "greeting": #{@valid_message},
    "introduction": #{@valid_message},
    "not_understood": #{@valid_message},
    "clarification": #{@valid_message},
    "threshold": 0.1
  })
  @valid_localized_keywords ~s({"en": ["a"]})
  @valid_keyword_responder ~s({
    "type": "keyword_responder",
    "id" : "1",
    "name" : "a",
    "explanation": #{@valid_empty_localized_string},
    "clarification": #{@valid_empty_localized_string},
    "keywords": #{@valid_localized_keywords},
    "response": #{@valid_localized_string}
  })
  @valid_delayed_message ~s({
    "delay": 1,
    "message": #{@valid_localized_string}
  })
  @valid_fixed_time_message ~s({
    "schedule": "2018-01-01T00:00:00Z",
    "message": #{@valid_localized_string}
  })
  @valid_daily_recurrent_message ~s({
    "recurrence": {
      "type": "daily",
      "start": "2018-01-01T00:00:00Z",
      "every": 3
    },
    "message": #{@valid_localized_string}
  })
  @valid_weekly_recurrent_message ~s({
    "recurrence": {
      "type": "weekly",
      "start": "2018-01-01T00:00:00Z",
      "every": 2,
      "on": ["monday", "friday"]
    },
    "message": #{@valid_localized_string}
  })
  @valid_monthly_recurrent_message ~s({
    "recurrence": {
      "type": "monthly",
      "start": "2018-01-01T00:00:00Z",
      "every": 2,
      "each": 5
    },
    "message": #{@valid_localized_string}
  })
  @valid_scheduled_messages ~s({
    "type": "scheduled_messages",
    "id": "2",
    "name": "a",
    "schedule_type": "since_last_incoming_message",
    "messages": [#{@valid_delayed_message}]
  })
  @valid_scheduled_messages_fixed_time ~s({
    "type": "scheduled_messages",
    "id": "2",
    "name": "a",
    "schedule_type": "fixed_time",
    "messages": [#{@valid_fixed_time_message}]
  })
  @valid_scheduled_messages_recurrent ~s({
    "type": "scheduled_messages",
    "id": "2",
    "name": "a",
    "schedule_type": "recurrent",
    "messages": [#{@valid_daily_recurrent_message}, #{@valid_weekly_recurrent_message}, #{@valid_monthly_recurrent_message}]
  })
  @valid_language_detector ~s({
    "type": "language_detector",
    "explanation": "a",
    "languages": #{@valid_localized_keywords}
  })
  @valid_choice ~s({
    "name": "a",
    "labels": #{@valid_localized_keywords},
    "attributes": {
      "foo": "x",
      "bar": 1
    }
  })
  @valid_choice_list ~s({
    "name": "a",
    "choices": [#{@valid_choice}]
  })
  @valid_select_question ~s({
    "type": "select_one",
    "choices": "a",
    "name": "a",
    "relevant": "${q} = 0",
    "message": #{@valid_localized_string},
    "choice_filter": "state = ${state}"
  })
  @valid_encrypted_select_question ~s({
    "type": "select_one",
    "choices": "a",
    "encrypt" : true,
    "name": "a",
    "relevant": "${q} = 0",
    "message": #{@valid_localized_string},
    "choice_filter": "state = ${state}"
  })
  @valid_input_question ~s({
    "type": "integer",
    "name": "a",
    "message": #{@valid_localized_string}
  })
  @valid_note ~s({
    "type": "note",
    "name": "a",
    "message": #{@valid_localized_string}
  })
  @valid_note_with_relevant ~s({
    "type": "note",
    "name": "a",
    "relevant": "true",
    "message": #{@valid_localized_string}
  })
  @valid_encrypted_input_question ~s({
    "type": "integer",
    "encrypt": true,
    "name": "a",
    "message": #{@valid_localized_string}
  })
  @valid_survey ~s({
    "type": "survey",
    "id": "2",
    "name": "a",
    "schedule": "2017-12-10T01:40:13.000-03:00",
    "keywords": #{@valid_localized_keywords},
    "questions": [#{@valid_input_question}, #{@valid_note}, #{@valid_select_question}, #{@valid_encrypted_input_question}, #{@valid_encrypted_select_question}, #{@valid_note_with_relevant}],
    "choice_lists": []
  })

  @valid_decision_tree ~s({
    "type": "decision_tree",
    "id": "2a516ba3-2e7b-48bf-b4c0-9b8cd55e003f",
    "name": "Food menu",
    "explanation": #{@valid_empty_localized_string},
    "clarification": #{@valid_empty_localized_string},
    "keywords": #{@valid_localized_keywords},
    "tree": {
      "question": #{@valid_localized_string},
      "responses": [
        {
          "keywords": #{@valid_localized_keywords},
          "next": {
            "question": #{@valid_localized_string},
            "responses": [
              {
                "keywords":#{@valid_localized_keywords},
                "next": {
                  "answer": #{@valid_localized_string}
                }
              },
              {
                "keywords": #{@valid_localized_keywords},
                "next": {
                  "answer": #{@valid_localized_string}
                }
              }
            ]
          }
        },
        {
          "keywords": #{@valid_localized_keywords},
          "next": {
            "question": #{@valid_localized_string},
            "responses": [
              {
                "keywords": #{@valid_localized_keywords},
                "next": {
                  "answer": #{@valid_localized_string}
                }
              },
              {
                "keywords": #{@valid_localized_keywords},
                "next": {
                  "question": #{@valid_localized_string},
                  "responses": [
                    {
                      "keywords": #{@valid_localized_keywords},
                      "next": {
                        "answer": #{@valid_localized_string}
                      }
                    },
                    {
                      "keywords": #{@valid_localized_keywords},
                      "next": {
                        "answer": #{@valid_localized_string}
                      }
                    }
                  ]
                }
              }
            ]
          }
        }
      ]
    }
  })

  @valid_variable ~s({
    "name": "a",
    "values": {
      "en": "a"
    },
    "overrides": [
      {
        "relevant": "${age} > 18",
        "values": {
          "en": "b"
        }
      }
    ]
  })
  @valid_facebook_channel ~s({
    "type": "facebook",
    "page_id": "1234567890",
    "verify_token": "qwertyuiopasdfghjklzxcvbnm",
    "access_token": "qwertyuiopasdfghjklzxcvbnm"
  })
  @valid_websocket_channel ~s({
    "type": "websocket",
    "access_token": "qwertyuiopasdfghjklzxcvbnm"
  })
  @valid_data_table ~s({
    "name": "t",
    "columns": ["a", "b", "c", "d"],
    "data": [
      ["1", "", 11, ""],
      ["2", 2.2, "", ""],
      [3, "", "", ""]
    ]
  })
  @valid_manifest ~s({
    "version" : "1",
    "languages" : ["en"],
    "front_desk" : #{@valid_front_desk},
    "skills" : [
      #{@valid_keyword_responder},
      #{@valid_scheduled_messages},
      #{@valid_language_detector},
      #{@valid_survey}
    ],
    "variables" : [],
    "channels" : [#{@valid_facebook_channel}, #{@valid_websocket_channel}],
    "public_keys": [#{@valid_base_64_key}],
    "data_tables": [#{@valid_data_table}]
  })

  defp validate(json_thing, type, fun) do
    validation_result = json_thing
    |> Poison.decode!
    |> JsonSchema.validate(type)

    apply(fun, [validation_result])
    |> assert(inspect validation_result)
  end

  defp assert_valid(json_thing, type) do
    validate(json_thing, type, fn(validation_result) ->
      [] == validation_result
    end)
  end

  defp assert_required(thing, type) do
    validate(~s({}), type, fn(validation_result) ->
      validation_result
      |> Enum.member?({"Required property #{thing} was not present.", []})
    end)
  end

  defp assert_optional(thing, valid_value, type) do
    validate(~s({}), type, fn(validation_result) ->
      !Enum.member?(validation_result, {"Required property #{thing} was not present.", []})
    end)

    validate(~s({"#{thing}": #{inspect valid_value}}), type, fn(validation_result) ->
      !Enum.member?(validation_result, {"Schema does not allow additional properties.", [thing]})
    end)
  end

  defp assert_dependency(thing, valid_value, dependency, type) do
    validate(~s({"#{thing}": #{inspect valid_value}}), type, fn(validation_result) ->
      Enum.member?(validation_result, {"Property #{thing} depends on #{dependency} to be present but it was not.", []})
    end)
  end

  defp assert_minimum_properties(type) do
    validate(~s({}), type, fn(validation_result) ->
      validation_result
      |> Enum.member?({"Expected a minimum of 1 properties but got 0", []})
    end)
  end

  defp assert_empty_array(thing, type) do
    validate(~s({"#{thing}": []}), type, fn(validation_result) ->
      !Enum.member?(validation_result, {"Expected a minimum of 1 items but got 0.", [thing]})
    end)
  end

  defp reject_empty_array(thing, type) do
    validate(~s({"#{thing}": []}), type, fn(validation_result) ->
      validation_result
      |> Enum.member?({"Expected a minimum of 1 items but got 0.", [thing]})
    end)
  end

  defp assert_valid_value(thing, value, type) do
    validate(~s({"#{thing}": #{Poison.encode!(value)}}), type, fn(validation_result) ->
      validation_result
      |> Enum.any?(fn
        {_, [^thing | _]} -> false
        _ -> true
      end)
    end)
  end

  defp assert_invalid_value(thing, value, type) do
    validate(~s({"#{thing}": #{Poison.encode!(value)}}), type, fn(validation_result) ->
      validation_result
      |> Enum.any?(fn
        {_, [^thing | _]} -> true
        _ -> false
      end)
    end)
  end

  defp reject_array_duplicates(thing, type) do
    validate(~s({"#{thing}": [1, 1]}), type, fn(validation_result) ->
      Enum.member?(validation_result, {"Expected items to be unique but they were not.", [thing]})
    end)
  end

  defp assert_integer(thing, type) do
    validate(~s({"#{thing}": {}}), type, fn(validation_result) ->
      validation_result
      |> Enum.member?({"Type mismatch. Expected Integer but got Object.", [thing]})
    end)
  end

  defp assert_boolean(thing, type) do
    validate(~s({"#{thing}": {}}), type, fn(validation_result) ->
      validation_result
      |> Enum.member?({"Type mismatch. Expected Boolean but got Object.", [thing]})
    end)
  end

  defp assert_array(thing, type) do
    validate(~s({"#{thing}": {}}), type, fn(validation_result) ->
      validation_result
      |> Enum.member?({"Type mismatch. Expected Array but got Object.", [thing]})
    end)
  end

  defp reject_sub_type(json_thing, type) do
    validate(json_thing, type, fn(validation_result) ->
      validation_result
      |> Enum.member?({"Expected exactly one of the schemata to match, but none of them did.", []})
    end)
  end

  defp assert_enum(thing, invalid_value, type) do
    validate(~s({"#{thing}": #{inspect invalid_value}}), type, fn(validation_result) ->
      validation_result
      |> Enum.member?({"Value #{inspect invalid_value} is not allowed in enum.", [thing]})
    end)
  end

  defp assert_valid_enum(thing, valid_value, type) do
    validate(~s({"#{thing}": #{inspect valid_value}}), type, fn(validation_result) ->
      !Enum.member?(validation_result, {"Value #{inspect valid_value} is not allowed in enum.", [thing]})
    end)
  end

  defp assert_max(thing, max_value, type) do
    validate(~s({"#{thing}": #{max_value + 1}}), type, fn(validation_result) ->
      validation_result
      |> Enum.member?({"Expected the value to be <= #{max_value}", [thing]})
    end)
  end

  defp assert_min(thing, min_value, type) do
    validate(~s({"#{thing}": #{min_value - 1}}), type, fn(validation_result) ->
      validation_result
      |> Enum.member?({"Expected the value to be >= #{min_value}", [thing]})
    end)
  end

  defp assert_non_empty_string(thing, type) do
    validate(~s({"#{thing}": ""}), type, fn(validation_result) ->
      validation_result
      |> Enum.member?({"Expected value to have a minimum length of 1 but was 0.", [thing]})
    end)
  end

  test "manifest_v1" do
    assert_required("version", :manifest_v1)
    assert_enum("version", "2", :manifest_v1)
    assert_valid_enum("type", "1", :manifest_v1)
    assert_required("languages", :manifest_v1)
    assert_required("skills", :manifest_v1)
    assert_required("variables", :manifest_v1)
    assert_required("front_desk", :manifest_v1)
    assert_array("skills", :manifest_v1)
    reject_empty_array("skills", :manifest_v1)
    assert_array("variables", :manifest_v1)
    assert_array("languages", :manifest_v1)
    reject_empty_array("languages", :manifest_v1)
    assert_required("channels", :manifest_v1)
    assert_array("channels", :manifest_v1)
    assert_array("public_keys", :manifest_v1)
    assert_optional("public_keys", [@valid_base_64_key], :manifest_v1)
    assert_valid_value("public_keys", [@valid_base_64_key], :manifest_v1)
    assert_invalid_value("public_keys", [@invalid_base_64_key], :manifest_v1)
    reject_empty_array("public_keys", :manifest_v1)
    assert_optional("data_tables", [@valid_data_table], :manifest_v1)

    @valid_manifest
    |> assert_valid(:manifest_v1)

    File.read!("test/fixtures/valid_manifest_single_lang.json")
    |> assert_valid(:manifest_v1)

    File.read!("test/fixtures/valid_manifest_with_skill_relevances.json")
    |> assert_valid(:manifest_v1)

    File.read!("test/fixtures/valid_manifest.json")
    |> assert_valid(:manifest_v1)
  end

  test "data_table" do
    assert_required("name", :data_table)
    assert_non_empty_string("name", :data_table)
    assert_required("columns", :data_table)
    reject_empty_array("columns", :data_table)
    assert_required("data", :data_table)
    reject_empty_array("data", :data_table)

    @valid_data_table
    |> assert_valid(:data_table)
  end

  test "keyword_responder" do
    assert_enum("type", "foo", :keyword_responder)
    assert_valid_enum("type", "keyword_responder", :keyword_responder)
    assert_required("type", :keyword_responder)
    assert_required("explanation", :keyword_responder)
    assert_required("clarification", :keyword_responder)
    assert_required("response", :keyword_responder)
    assert_required("keywords", :keyword_responder)
    assert_required("name", :keyword_responder)
    assert_non_empty_string("name", :keyword_responder)
    assert_required("id", :keyword_responder)
    assert_non_empty_string("id", :keyword_responder)
    assert_optional("relevant", "${age} > 18", :keyword_responder)

    @valid_keyword_responder
    |> assert_valid(:keyword_responder)
  end

  test "scheduled_messages" do
    subtypes = [
      :scheduled_messages_since_last_incoming_message,
      :scheduled_messages_fixed_time,
      :scheduled_messages_recurrent
    ]

    subtypes |> Enum.each(fn type ->
      assert_enum("type", "foo", type)
      assert_valid_enum("type", "scheduled_messages", type)
      assert_required("type", type)
      assert_required("schedule_type", type)
      assert_enum("schedule_type", "foo", type)
      assert_required("messages", type)
      assert_array("messages", type)
      reject_empty_array("messages", type)
      assert_non_empty_string("name", type)
      assert_required("name", type)
      assert_non_empty_string("id", type)
      assert_required("id", type)
      assert_optional("relevant", "${age} > 18", type)
    end)

    assert_valid_enum("schedule_type", "since_last_incoming_message", :scheduled_messages_since_last_incoming_message)
    assert_valid_enum("schedule_type", "fixed_time", :scheduled_messages_fixed_time)
    assert_valid_enum("schedule_type", "recurrent", :scheduled_messages_recurrent)

    @valid_scheduled_messages
    |> assert_valid(:scheduled_messages)

    @valid_scheduled_messages_fixed_time
    |> assert_valid(:scheduled_messages)

    @valid_scheduled_messages_recurrent
    |> assert_valid(:scheduled_messages_recurrent)
  end

  test "delayed_message" do
    assert_required("delay", :delayed_message)
    assert_integer("delay", :delayed_message)
    assert_min("delay", 1, :delayed_message)
    assert_required("message", :delayed_message)

    @valid_delayed_message
    |> assert_valid(:delayed_message)
  end

  test "recurrent_message" do
    assert_required("recurrence", :recurrent_message)
    assert_required("message", :recurrent_message)
  end

  test "recurrence_daily" do
    assert_enum("type", "foo", :recurrence_daily)
    assert_valid_enum("type", "daily", :recurrence_daily)
    assert_required("start", :recurrence_daily)
    assert_required("every", :recurrence_daily)
    assert_integer("every", :recurrence_daily)
    assert_min("every", 1, :recurrence_daily)
  end

  test "recurrence_weekly" do
    assert_enum("type", "foo", :recurrence_weekly)
    assert_valid_enum("type", "weekly", :recurrence_weekly)
    assert_required("start", :recurrence_weekly)
    assert_required("every", :recurrence_weekly)
    assert_integer("every", :recurrence_weekly)
    assert_min("every", 1, :recurrence_weekly)
    assert_required("on", :recurrence_weekly)
    assert_array("on", :recurrence_weekly)
    reject_empty_array("on", :recurrence_weekly)
    assert_valid_value("on", ~w[monday tuesday wednesday thursday friday saturday sunday], :recurrence_weekly)
    assert_invalid_value("on", ~w[foo], :recurrence_weekly)
    reject_array_duplicates("on", :recurrence_weekly)
  end

  test "recurrence_monthly" do
    assert_enum("type", "foo", :recurrence_monthly)
    assert_valid_enum("type", "monthly", :recurrence_monthly)
    assert_required("start", :recurrence_monthly)
    assert_required("every", :recurrence_monthly)
    assert_integer("every", :recurrence_monthly)
    assert_min("every", 1, :recurrence_monthly)
    assert_required("each", :recurrence_monthly)
    assert_integer("each", :recurrence_monthly)
    assert_min("each", 1, :recurrence_monthly)
    assert_max("each", 31, :recurrence_monthly)
  end

  test "language_detector" do
    assert_enum("type", "foo", :language_detector)
    assert_valid_enum("type", "language_detector", :language_detector)
    assert_required("type", :language_detector)
    assert_required("explanation", :language_detector)
    assert_required("languages", :language_detector)
    assert_boolean("reply_to_unsupported_language", :language_detector)

    @valid_language_detector
    |> assert_valid(:language_detector)
  end

  test "survey" do
    assert_enum("type", "foo", :survey)
    assert_valid_enum("type", "survey", :survey)
    assert_required("type", :survey)
    assert_required("schedule", :survey)
    assert_required("name", :survey)
    assert_non_empty_string("name", :survey)
    assert_required("id", :survey)
    assert_non_empty_string("id", :survey)
    assert_required("questions", :survey)
    reject_empty_array("questions", :survey)
    assert_array("questions", :survey)
    assert_required("choice_lists", :survey)
    assert_array("choice_lists", :survey)
    assert_empty_array("choice_lists", :survey)
    assert_optional("relevant", "${age} > 18", :survey)

    @valid_survey
    |> assert_valid(:survey)
  end


  test "decision_tree" do
    assert_enum("type", "foo", :decision_tree)
    assert_valid_enum("type", "decision_tree", :decision_tree)
    assert_required("type", :decision_tree)
    assert_required("name", :decision_tree)
    assert_non_empty_string("name", :decision_tree)
    assert_required("id", :decision_tree)
    assert_non_empty_string("id", :decision_tree)
    assert_required("tree", :decision_tree)
    assert_required("explanation", :decision_tree)
    assert_required("clarification", :decision_tree)
    assert_required("keywords", :decision_tree)
    assert_optional("relevant", "${age} > 18", :decision_tree)

    @valid_decision_tree
    |> assert_valid(:decision_tree)
  end

  test "input_question" do
    assert_required("type", :input_question)
    assert_enum("type", "foo", :input_question)
    assert_valid_enum("type", "integer", :input_question)
    assert_valid_enum("type", "decimal", :input_question)
    assert_valid_enum("type", "text", :input_question)
    assert_valid_enum("type", "image", :input_question)
    assert_required("name", :input_question)
    assert_non_empty_string("name", :input_question)
    assert_required("message", :input_question)
    assert_optional("relevant", "${q} > 0", :input_question)
    assert_optional("constraint", ". < 10", :input_question)
    assert_optional("constraint_message", "error", :input_question)
    assert_dependency("constraint", ". < 10", "constraint_message", :input_question)

    @valid_input_question
    |> assert_valid(:input_question)
  end

  test "encrypted input_question" do
    @valid_encrypted_input_question
    |> assert_valid(:input_question)
  end

  test "select_question" do
    assert_required("type", :select_question)
    assert_enum("type", "foo", :select_question)
    assert_valid_enum("type", "select_one", :select_question)
    assert_valid_enum("type", "select_many", :select_question)
    assert_required("choices", :select_question)
    assert_non_empty_string("choices", :select_question)
    assert_required("name", :select_question)
    assert_non_empty_string("name", :select_question)
    assert_required("message", :select_question)
    assert_optional("relevant", "${q} > 0", :select_question)
    assert_optional("constraint_message", "error", :select_question)
    assert_optional("choice_filter", "${q} = q", :select_question)

    @valid_select_question
    |> assert_valid(:select_question)
  end

  test "encrypted select_question" do
    @valid_encrypted_select_question
    |> assert_valid(:select_question)
  end

  test "survey note" do
    @valid_note
    |> assert_valid(:note)
  end

  test "choice" do
    assert_required("name", :choice)
    assert_non_empty_string("name", :choice)
    assert_required("labels", :choice)
    assert_optional("attributes", {}, :choice)

    @valid_choice
    |> assert_valid(:choice)
  end

  test "choice_list" do
    assert_required("name", :choice_list)
    assert_non_empty_string("name", :choice_list)
    assert_required("choices", :choice_list)
    reject_empty_array("choices", :choice_list)
    assert_array("choices", :choice_list)

    @valid_choice_list
    |> assert_valid(:choice_list)
  end

  test "question" do
    @valid_input_question
    |> assert_valid(:question)

    @valid_select_question
    |> assert_valid(:question)

    ~s({})
    |> reject_sub_type(:question)
  end

  test "skill" do
    @valid_keyword_responder
    |> assert_valid(:skill)

    @valid_language_detector
    |> assert_valid(:skill)

    @valid_scheduled_messages
    |> assert_valid(:skill)

    @valid_survey
    |> assert_valid(:skill)

    ~s({})
    |> reject_sub_type(:skill)
  end

  test "front_desk" do
    assert_required("greeting", :front_desk)
    assert_required("introduction", :front_desk)
    assert_required("not_understood", :front_desk)
    assert_required("clarification", :front_desk)
    assert_required("threshold", :front_desk)
    assert_max("threshold", 0.5, :front_desk)
    assert_min("threshold", 0, :front_desk)

    @valid_front_desk
    |> assert_valid(:front_desk)
  end

  test "message" do
    assert_required("message", :message)

    @valid_message
    |> assert_valid(:message)
  end

  test "variable" do
    assert_required("name", :variable)
    assert_non_empty_string("name", :variable)
    assert_required("values", :variable)
    assert_optional("overrides", [], :variable)

    @valid_variable
    |> assert_valid(:variable)
  end

  test "variable_override" do
    assert_required("relevant", :variable_override)
    assert_required("values", :variable_override)
  end

  test "localized_string" do
    assert_minimum_properties(:localized_string)

    @valid_localized_string
    |> assert_valid(:localized_string)
  end

  test "localized_keywords" do
    assert_minimum_properties(:localized_keywords)
    assert_array("en", :localized_keywords)
    reject_empty_array("en", :localized_keywords)

    @valid_localized_keywords
    |> assert_valid(:localized_keywords)
  end

  test "facebook_channel" do
    assert_enum("type", "foo", :facebook_channel)
    assert_valid_enum("type", "facebook", :facebook_channel)
    assert_required("type", :facebook_channel)
    assert_required("page_id", :facebook_channel)
    assert_non_empty_string("page_id", :facebook_channel)
    assert_required("verify_token", :facebook_channel)
    assert_non_empty_string("verify_token", :facebook_channel)
    assert_required("access_token", :facebook_channel)
    assert_non_empty_string("access_token", :facebook_channel)

    @valid_facebook_channel
    |> assert_valid(:facebook_channel)
  end

  test "websocket_channel" do
    assert_enum("type", "foo", :websocket_channel)
    assert_valid_enum("type", "websocket", :websocket_channel)
    assert_required("type", :websocket_channel)
    assert_required("access_token", :websocket_channel)
    assert_non_empty_string("access_token", :websocket_channel)

    @valid_websocket_channel
    |> assert_valid(:websocket_channel)
  end

  test "channel" do
    @valid_facebook_channel
    |> assert_valid(:channel)

    @valid_websocket_channel
    |> assert_valid(:channel)

    ~s({})
    |> reject_sub_type(:channel)
  end
end
