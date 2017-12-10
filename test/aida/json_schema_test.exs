defmodule Aida.JsonSchemaTest do
  use ExUnit.Case

  alias Aida.JsonSchema

  setup_all do
    GenServer.start_link(JsonSchema, [], name: JsonSchema.server_ref)
    :ok
  end

  @valid_localized_string ~s({"en": ""})
  @valid_message ~s({"message" : #{@valid_localized_string}})
  @valid_front_desk ~s({
    "greeting": #{@valid_message},
    "introduction": #{@valid_message},
    "not_understood": #{@valid_message},
    "clarification": #{@valid_message},
    "threshold": 0.1
  })
  @valid_localized_keywords ~s({"en": [""]})
  @valid_keyword_responder ~s({
    "type": "keyword_responder",
    "id" : "1",
    "name" : "",
    "explanation": #{@valid_localized_string},
    "clarification": #{@valid_localized_string},
    "keywords": #{@valid_localized_keywords},
    "response": #{@valid_localized_string}
  })
  @valid_delayed_message ~s({
    "delay": "1",
    "message": #{@valid_localized_string}
  })
  @valid_scheduled_messages ~s({
    "type": "scheduled_messages",
    "id": "2",
    "name": "",
    "schedule_type": "since_last_incoming_message",
    "messages": [#{@valid_delayed_message}]
  })
  @valid_language_detector ~s({
    "type": "language_detector",
    "explanation": "",
    "languages": #{@valid_localized_keywords}
  })
  @valid_choice ~s({
    "name": "",
    "labels": #{@valid_localized_keywords}
  })
  @valid_choice_list ~s({
    "name": "",
    "choices": [#{@valid_choice}]
  })
  @valid_select_question ~s({
    "type": "select_one",
    "choices": "",
    "name": "",
    "message": #{@valid_localized_string}
  })
  @valid_input_question ~s({
    "type": "integer",
    "name": "",
    "message": #{@valid_localized_string}
  })
  @valid_survey ~s({
    "type": "survey",
    "id": "2",
    "name": "",
    "schedule": "",
    "questions": [#{@valid_input_question}],
    "choice_lists": []
  })
  @valid_variable ~s({
    "name": "",
    "values": {
      "en": ""
    }
  })
  @valid_facebook_channel ~s({
    "type": "facebook",
    "page_id": "1234567890",
    "verify_token": "qwertyuiopasdfghjklzxcvbnm",
    "access_token": "qwertyuiopasdfghjklzxcvbnm"
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
    "channels" : [#{@valid_facebook_channel}]
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

  defp assert_max(json_thing, thing, max_value, type) do
    validate(json_thing, type, fn(validation_result) ->
      validation_result
      |> Enum.member?({"Expected the value to be <= #{max_value}", [thing]})
    end)
  end

  defp assert_min(json_thing, thing, min_value, type) do
    validate(json_thing, type, fn(validation_result) ->
      validation_result
      |> Enum.member?({"Expected the value to be >= #{min_value}", [thing]})
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

    @valid_manifest
    |> assert_valid(:manifest_v1)

    File.read!("test/fixtures/valid_manifest_single_lang.json")
    |> assert_valid(:manifest_v1)

    File.read!("test/fixtures/valid_manifest.json")
    |> assert_valid(:manifest_v1)
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
    assert_required("id", :keyword_responder)

    @valid_keyword_responder
    |> assert_valid(:keyword_responder)
  end

  test "scheduled_messages" do
    assert_enum("type", "foo", :scheduled_messages)
    assert_valid_enum("type", "scheduled_messages", :scheduled_messages)
    assert_required("type", :scheduled_messages)
    assert_required("schedule_type", :scheduled_messages)
    assert_enum("schedule_type", "foo", :scheduled_messages)
    assert_valid_enum("schedule_type", "since_last_incoming_message", :since_last_incoming_message)
    assert_required("messages", :scheduled_messages)
    assert_array("messages", :scheduled_messages)
    reject_empty_array("messages", :scheduled_messages)
    assert_required("name", :scheduled_messages)
    assert_required("id", :scheduled_messages)

    @valid_scheduled_messages
    |> assert_valid(:scheduled_messages)
  end

  test "delayed_message" do
    assert_required("delay", :delayed_message)
    assert_required("message", :delayed_message)

    @valid_delayed_message
    |> assert_valid(:delayed_message)
  end

  test "language_detector" do
    assert_enum("type", "foo", :language_detector)
    assert_valid_enum("type", "language_detector", :language_detector)
    assert_required("type", :language_detector)
    assert_required("explanation", :language_detector)
    assert_required("languages", :language_detector)

    @valid_language_detector
    |> assert_valid(:language_detector)
  end

  test "survey" do
    assert_enum("type", "foo", :survey)
    assert_valid_enum("type", "survey", :survey)
    assert_required("type", :survey)
    assert_required("schedule", :survey)
    assert_required("name", :survey)
    assert_required("id", :survey)
    assert_required("questions", :survey)
    reject_empty_array("questions", :survey)
    assert_array("questions", :survey)
    assert_required("choice_lists", :survey)
    assert_array("choice_lists", :survey)
    assert_empty_array("choice_lists", :survey)

    @valid_survey
    |> assert_valid(:survey)
  end

  test "input_question" do
    assert_required("type", :input_question)
    assert_enum("type", "foo", :input_question)
    assert_valid_enum("type", "integer", :input_question)
    assert_valid_enum("type", "decimal", :input_question)
    assert_valid_enum("type", "text", :input_question)
    assert_required("name", :input_question)
    assert_required("message", :input_question)

    @valid_input_question
    |> assert_valid(:input_question)
  end

  test "select_question" do
    assert_required("type", :select_question)
    assert_enum("type", "foo", :select_question)
    assert_valid_enum("type", "select_one", :select_question)
    assert_valid_enum("type", "select_many", :select_question)
    assert_required("choices", :select_question)
    assert_required("name", :select_question)
    assert_required("message", :select_question)

    @valid_select_question
    |> assert_valid(:select_question)
  end

  test "choice" do
    assert_required("name", :choice)
    assert_required("labels", :choice)

    @valid_choice
    |> assert_valid(:choice)
  end

  test "choice_list" do
    assert_required("name", :choice_list)
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

    ~s({"threshold": 2})
    |> assert_max("threshold", 1, :front_desk)

    ~s({"threshold": -1})
    |> assert_min("threshold", 0, :front_desk)

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
    assert_required("values", :variable)

    @valid_variable
    |> assert_valid(:variable)
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
    assert_required("verify_token", :facebook_channel)
    assert_required("access_token", :facebook_channel)

    @valid_facebook_channel
    |> assert_valid(:facebook_channel)
  end

  test "channel" do
    @valid_facebook_channel
    |> assert_valid(:channel)

    ~s({})
    |> reject_sub_type(:channel)
  end
end
