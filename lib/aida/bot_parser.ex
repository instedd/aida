defmodule Aida.BotParser do
  alias Aida.{
    Bot,
    DataTable,
    FrontDesk,
    Skill,
    Skill.DecisionTree,
    Skill.HumanOverride,
    Skill.KeywordResponder,
    Skill.LanguageDetector,
    Skill.ScheduledMessages,
    Skill.Survey,
    Variable,
    Channel.Facebook,
    Channel.WebSocket,
    Recurrence,
    Unsubscribe,
    WitAi,
    Engine.WitAIEngine
  }

  @spec parse(id :: String.t(), manifest :: map) ::
          {:ok, Bot.t()} | {:error, reason :: String.t() | map}
  def parse(id, manifest) do
    try do
      %Bot{
        id: id,
        languages: manifest["languages"],
        notifications_url: manifest["notifications_url"],
        front_desk: parse_front_desk(manifest["front_desk"]),
        skills: manifest["skills"] |> Enum.map(&parse_skill(&1, id)),
        variables: manifest["variables"] |> Enum.map(&parse_variable/1),
        channels: manifest["channels"] |> Enum.map(&parse_channel(id, &1)),
        public_keys: parse_public_keys(manifest["public_keys"]),
        data_tables: (manifest["data_tables"] || []) |> Enum.map(&parse_data_table/1),
        natural_language_interface:
          parse_natural_language_interface(manifest["natural_language_interface"])
      }
      |> validate()
    rescue
      error -> {:error, Exception.message(error)}
    end
  end

  def parse!(id, manifest) do
    case parse(id, manifest) do
      {:ok, bot} -> bot
      {:error, reason} -> raise reason
    end
  end

  @spec parse_natural_language_interface(natural_language_interface :: map) :: WitAi.t()

  defp parse_natural_language_interface(%{"auth_token" => auth_token, "provider" => "wit_ai"}) do
    %WitAi{
      auth_token: auth_token
    }
  end

  defp parse_natural_language_interface(_) do
    nil
  end

  @spec parse_front_desk(front_desk :: map) :: FrontDesk.t()
  defp parse_front_desk(front_desk) do
    %FrontDesk{
      threshold: front_desk["threshold"],
      greeting: front_desk["greeting"]["message"],
      introduction: front_desk["introduction"]["message"],
      not_understood: front_desk["not_understood"]["message"],
      clarification: front_desk["clarification"]["message"],
      unsubscribe: parse_unsubscribe(front_desk["unsubscribe"])
    }
  end

  @spec parse_unsubscribe(unsubscribe :: map) :: Unsubscribe.t()
  defp parse_unsubscribe(unsubscribe) do
    %Unsubscribe{
      introduction_message: unsubscribe["introduction_message"]["message"],
      keywords: parse_string_list_map(unsubscribe["keywords"]),
      acknowledge_message: unsubscribe["acknowledge_message"]["message"]
    }
  end

  @spec parse_data_table(data_table :: map) :: DataTable.t()
  defp parse_data_table(data_table) do
    %DataTable{
      name: data_table["name"],
      columns: data_table["columns"],
      data: data_table["data"]
    }
  end

  @spec parse_variable(var :: map) :: Variable.t()
  defp parse_variable(var) do
    %Variable{
      name: var["name"],
      values: var["values"],
      overrides: parse_variable_overrides(var["overrides"])
    }
  end

  @spec parse_variable_overrides(overrides :: nil | list) :: [Variable.Override.t()]
  defp parse_variable_overrides(nil), do: []

  defp parse_variable_overrides(overrides) do
    overrides |> Enum.map(&parse_variable_override/1)
  end

  @spec parse_variable_override(override :: map) :: Variable.Override.t()
  defp parse_variable_override(override) do
    %Variable.Override{
      relevant: parse_expr(override["relevant"]),
      values: override["values"]
    }
  end

  defp parse_skill(%{"type" => "language_detector"} = skill, bot_id) do
    %LanguageDetector{
      explanation: skill["explanation"],
      bot_id: bot_id,
      languages: parse_string_list_map(skill["languages"]),
      reply_to_unsupported_language: skill["reply_to_unsupported_language"] == true
    }
  end

  defp parse_skill(%{"type" => "keyword_responder"} = skill, bot_id) do
    %KeywordResponder{
      explanation: skill["explanation"],
      bot_id: bot_id,
      clarification: skill["clarification"],
      id: skill["id"],
      name: skill["name"],
      keywords: parse_string_list_map(skill["keywords"]),
      training_sentences: parse_string_list_map(skill["training_sentences"], false),
      response: skill["response"],
      relevant: parse_expr(skill["relevant"])
    }
  end

  defp parse_skill(%{"type" => "scheduled_messages"} = skill, bot_id) do
    schedule_type =
      case skill["schedule_type"] do
        "since_last_incoming_message" -> :since_last_incoming_message
        "fixed_time" -> :fixed_time
        "recurrent" -> :recurrent
      end

    %ScheduledMessages{
      id: skill["id"],
      bot_id: bot_id,
      name: skill["name"],
      schedule_type: schedule_type,
      relevant: parse_expr(skill["relevant"]),
      messages: skill["messages"] |> Enum.map(&parse_scheduled_message(&1, schedule_type))
    }
  end

  defp parse_skill(%{"type" => "survey"} = skill, bot_id) do
    {:ok, schedule, _} =
      case skill["schedule"] do
        nil ->
          {:ok, nil, nil}

        schedule ->
          schedule |> DateTime.from_iso8601()
      end

    choice_lists =
      skill["choice_lists"] |> Enum.map(&parse_survey_choice_list/1) |> Enum.into(%{})

    %Survey{
      id: skill["id"],
      bot_id: bot_id,
      name: skill["name"],
      schedule: schedule,
      keywords: parse_string_list_map(skill["keywords"]),
      training_sentences: parse_string_list_map(skill["training_sentences"], false),
      relevant: parse_expr(skill["relevant"]),
      questions: skill["questions"] |> Enum.map(&parse_survey_question(&1, choice_lists))
    }
  end

  defp parse_skill(%{"type" => "decision_tree"} = skill, bot_id) do
    %DecisionTree{
      id: skill["id"],
      bot_id: bot_id,
      name: skill["name"],
      explanation: skill["explanation"],
      clarification: skill["clarification"],
      keywords: parse_string_list_map(skill["keywords"]),
      training_sentences: parse_string_list_map(skill["training_sentences"], false),
      relevant: parse_expr(skill["relevant"]),
      root_id: skill["tree"]["id"],
      tree: DecisionTree.flatten(skill["tree"])
    }
  end

  defp parse_skill(%{"type" => "human_override"} = skill, bot_id) do
    %HumanOverride{
      id: skill["id"],
      bot_id: bot_id,
      name: skill["name"],
      explanation: skill["explanation"],
      clarification: skill["clarification"],
      keywords: parse_string_list_map(skill["keywords"]),
      training_sentences: parse_string_list_map(skill["training_sentences"], false),
      relevant: parse_expr(skill["relevant"]),
      in_hours_response: skill["in_hours_response"],
      off_hours_response: skill["off_hours_response"],
      in_hours: skill["in_hours"]
    }
  end

  defp parse_scheduled_message(message, :since_last_incoming_message) do
    %ScheduledMessages.DelayedMessage{
      delay: message["delay"],
      message: message["message"]
    }
  end

  defp parse_scheduled_message(message, :fixed_time) do
    {:ok, schedule, _} = message["schedule"] |> DateTime.from_iso8601()

    %ScheduledMessages.FixedTimeMessage{
      schedule: schedule,
      message: message["message"]
    }
  end

  defp parse_scheduled_message(message, :recurrent) do
    %ScheduledMessages.RecurrentMessage{
      recurrence: parse_recurrence(message["recurrence"]),
      message: message["message"]
    }
  end

  defp parse_recurrence(%{"type" => "daily"} = recurrence) do
    {:ok, start, _} = recurrence["start"] |> DateTime.from_iso8601()

    %Recurrence.Daily{
      start: start,
      every: recurrence["every"]
    }
  end

  defp parse_recurrence(%{"type" => "weekly"} = recurrence) do
    {:ok, start, _} = recurrence["start"] |> DateTime.from_iso8601()

    %Recurrence.Weekly{
      start: start,
      every: recurrence["every"],
      on: recurrence["on"] |> Enum.map(&parse_weekday/1)
    }
  end

  defp parse_recurrence(%{"type" => "monthly"} = recurrence) do
    {:ok, start, _} = recurrence["start"] |> DateTime.from_iso8601()

    %Recurrence.Monthly{
      start: start,
      every: recurrence["every"],
      each: recurrence["each"]
    }
  end

  defp parse_weekday("sunday"), do: :sunday
  defp parse_weekday("monday"), do: :monday
  defp parse_weekday("tuesday"), do: :tuesday
  defp parse_weekday("wednesday"), do: :wednesday
  defp parse_weekday("thursday"), do: :thursday
  defp parse_weekday("friday"), do: :friday
  defp parse_weekday("saturday"), do: :saturday

  defp parse_survey_question(question, choice_lists) do
    question_type =
      case question["type"] do
        "integer" -> :integer
        "decimal" -> :decimal
        "image" -> :image
        "text" -> :text
        "select_one" -> :select_one
        "select_many" -> :select_many
        "note" -> :note
      end

    parse_survey_question(question_type, question, choice_lists)
  end

  defp parse_survey_question(question_type, question, choice_lists)
       when question_type == :select_one or question_type == :select_many do
    %Survey.SelectQuestion{
      type: question_type,
      choices: choice_lists[question["choices"]],
      name: question["name"],
      encrypt: question["encrypt"] || false,
      relevant: parse_expr(question["relevant"]),
      message: question["message"],
      constraint_message: question["constraint_message"],
      choice_filter: parse_expr(question["choice_filter"])
    }
  end

  defp parse_survey_question(question_type, question, _) when question_type == :note do
    %Survey.Note{
      type: question_type,
      name: question["name"],
      relevant: parse_expr(question["relevant"]),
      message: question["message"]
    }
  end

  defp parse_survey_question(question_type, question, _) do
    %Survey.InputQuestion{
      type: question_type,
      name: question["name"],
      encrypt: question["encrypt"] || false,
      relevant: parse_expr(question["relevant"]),
      message: question["message"],
      constraint: parse_expr(question["constraint"]),
      constraint_message: question["constraint_message"]
    }
  end

  defp parse_expr(nil), do: nil

  defp parse_expr(code) do
    Aida.Expr.parse(code)
  end

  defp parse_survey_choice_list(choice_list) do
    {
      choice_list["name"],
      choice_list["choices"] |> Enum.map(&parse_survey_choice/1)
    }
  end

  defp parse_survey_choice(choice) do
    %Survey.Choice{
      name: choice["name"],
      labels: parse_string_list_map(choice["labels"]),
      attributes: choice["attributes"]
    }
  end

  defp parse_channel(bot_id, %{"type" => "facebook"} = channel) do
    %Facebook{
      bot_id: bot_id,
      page_id: channel["page_id"],
      verify_token: channel["verify_token"],
      access_token: channel["access_token"]
    }
  end

  defp parse_channel(bot_id, %{"type" => "websocket"} = channel) do
    %WebSocket{
      bot_id: bot_id,
      access_token: channel["access_token"]
    }
  end

  def parse_public_keys(nil), do: []

  def parse_public_keys(public_keys) do
    public_keys
    |> Enum.map(&Base.decode64!/1)
  end

  defp parse_string_list_map(string_list_map, downcase \\ true) do
    if string_list_map do
      string_list_map
      |> Enum.map(fn {key, value} -> {key, parse_string_list(value, downcase)} end)
      |> Enum.into(%{})
    end
  end

  defp parse_string_list(string_list, downcase) do
    string_list
    |> Enum.map(&(&1 |> String.trim() |> downcase_string(downcase)))
  end

  defp downcase_string(string, true) do
    string |> String.downcase()
  end

  defp downcase_string(string, _) do
    string
  end

  defp validate(bot) do
    with :ok <- validate_skill_id_uniqueness(bot),
         :ok <- validate_required_public_keys(bot),
         :ok <- validate_natural_language_interface_presence(bot),
         :ok <- validate_natural_language_interface_credentials(bot),
         :ok <- validate_keywords_and_training_sentences(bot),
         :ok <- validate_keywords_or_training_sentences(bot),
         :ok <- validate_only_english_training_sentences(bot) do
      {:ok, bot}
    else
      err -> err
    end
  end

  defp validate_skill_id_uniqueness(%{skills: skills}) do
    duplicated_skills =
      skills
      |> Enum.group_by(fn skill -> skill |> Skill.id() end)
      |> Map.to_list()
      |> Enum.find(fn {_, skills} -> Enum.count(skills) > 1 end)

    case duplicated_skills do
      nil ->
        :ok

      {id, _} ->
        [paths, _] =
          skills
          |> Enum.reduce([[], 0], fn skill, [paths, index] ->
            if skill |> Skill.id() == id do
              [["#/skills/#{index}" | paths], index + 1]
            else
              [paths, index + 1]
            end
          end)

        {:error, %{"message" => "Duplicated skills (#{id})", "path" => paths}}
    end
  end

  defp validate_only_english_training_sentences(%{skills: skills}) do
    not_only_english_training_sentences_skill =
      skills
      |> Enum.filter(
        &match?(
          %{
            :training_sentences => training_sentences
          }
          when training_sentences != nil,
          &1
        )
      )
      |> Enum.find(fn %{:training_sentences => training_sentences} ->
        Map.get(training_sentences, "en") == nil or
          Map.keys(training_sentences) |> Kernel.length() > 1
      end)

    case not_only_english_training_sentences_skill do
      nil ->
        :ok

      %{:id => id} ->
        [paths, _] =
          skills
          |> Enum.reduce([[], 0], fn skill, [paths, index] ->
            if skill |> Skill.id() == id do
              [["#/skills/#{index}/training_sentences"], index + 1]
            else
              [paths, index + 1]
            end
          end)

        {:error,
         %{
           "message" => "Training_sentences are valid only in english",
           "path" => paths
         }}
    end
  end

  defp validate_keywords_or_training_sentences(%{skills: skills}) do
    neither_keywords_nor_training_sentences_skill =
      skills
      |> Enum.find(
        &match?(
          %type{
            :training_sentences => training_sentences,
            :keywords => keywords
          }
          when training_sentences == nil and keywords == nil and
                 type in [
                   Aida.Skill.KeywordResponder,
                   Aida.Skill.HumanOverride,
                   Aida.Skill.DecisionTree
                 ],
          &1
        )
      )

    case neither_keywords_nor_training_sentences_skill do
      nil ->
        :ok

      %{:id => id} ->
        [paths, _] =
          skills
          |> Enum.reduce([[], 0], fn skill, [paths, index] ->
            if skill |> Skill.id() == id do
              [["#/skills/#{index}/keywords", "#/skills/#{index}/training_sentences"], index + 1]
            else
              [paths, index + 1]
            end
          end)

        {:error,
         %{
           "message" => "One of keywords or training_sentences required",
           "path" => paths
         }}
    end
  end

  defp validate_keywords_and_training_sentences(%{skills: skills}) do
    keywords_and_training_sentences_skill =
      skills
      |> Enum.find(
        &match?(
          %{
            :training_sentences => training_sentences,
            :keywords => keywords
          }
          when training_sentences != nil and keywords != nil,
          &1
        )
      )

    case keywords_and_training_sentences_skill do
      nil ->
        :ok

      %{:id => id} ->
        [paths, _] =
          skills
          |> Enum.reduce([[], 0], fn skill, [paths, index] ->
            if skill |> Skill.id() == id do
              [["#/skills/#{index}/keywords", "#/skills/#{index}/training_sentences"], index + 1]
            else
              [paths, index + 1]
            end
          end)

        {:error,
         %{
           "message" => "Keywords and training_sentences in the same skill",
           "path" => paths
         }}
    end
  end

  def validate_natural_language_interface_presence(%Aida.Bot{
        :natural_language_interface => nil,
        :skills => skills
      }) do
    case Enum.any?(
           skills,
           &match?(
             %{:training_sentences => training_sentences} when training_sentences != nil,
             &1
           )
         ) do
      true ->
        {:error,
         %{
           "message" => "Missing natural_language_interface in manifest",
           "path" => "#/natural_language_interface"
         }}

      _ ->
        :ok
    end
  end

  def validate_natural_language_interface_presence(_) do
    :ok
  end

  def validate_natural_language_interface_credentials(%Aida.Bot{
        :natural_language_interface => nil
      }) do
    :ok
  end

  def validate_natural_language_interface_credentials(%Aida.Bot{
        natural_language_interface: %Aida.WitAi{auth_token: _} = natural_language_interface
      }) do
    case WitAIEngine.check_credentials(natural_language_interface) do
      :ok ->
        :ok

      _ ->
        {:error,
         %{
           "message" => "Invalid wit ai credentials in manifest",
           "path" => "#/natural_language_interface"
         }}
    end
  end

  def validate_natural_language_interface_credentials(_) do
    {:error,
     %{
       "message" => "Invalid natural language interface in manifest",
       "path" => "#/natural_language_interface"
     }}
  end

  def validate_required_public_keys(%{skills: skills, public_keys: []}) do
    case skills |> Enum.any?(&Skill.uses_encryption?/1) do
      true ->
        {:error, %{"message" => "Missing public_keys in manifest", "path" => "#/public_keys"}}

      _ ->
        :ok
    end
  end

  def validate_required_public_keys(%{public_keys: _}) do
    :ok
  end
end
