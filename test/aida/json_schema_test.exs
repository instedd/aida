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
    "version" : 1,
    "languages" : ["en"],
    "front_desk" : #{@valid_front_desk},
    "skills" : [#{@valid_keyword_responder}],
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
    assert_enum("version", 2, :manifest_v1)
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

  test "skill" do
    @valid_keyword_responder
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
