defmodule Aida.BotParser do
  alias Aida.{
    Bot,
    FrontDesk,
    Skill,
    Skill.KeywordResponder,
    Skill.LanguageDetector,
    Skill.ScheduledMessages,
    Skill.Survey,
    DelayedMessage,
    FixedTimeMessage,
    SelectQuestion,
    InputQuestion,
    Choice,
    Variable,
    Channel.Facebook,
    Channel.WebSocket
  }

  @spec parse(id :: String.t, manifest :: map) :: {:ok, Bot.t} | {:error, reason :: String.t}
  def parse(id, manifest) do
    try do
      %Bot{
        id: id,
        languages: manifest["languages"],
        front_desk: parse_front_desk(manifest["front_desk"]),
        skills: manifest["skills"] |> Enum.map(&(parse_skill(&1, id))),
        variables: manifest["variables"] |> Enum.map(&parse_variable/1),
        channels: manifest["channels"] |> Enum.map(&(parse_channel(id, &1)))
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

  @spec parse_front_desk(front_desk :: map) :: FrontDesk.t
  defp parse_front_desk(front_desk) do
    %FrontDesk{
      threshold: front_desk["threshold"],
      greeting: front_desk["greeting"]["message"],
      introduction: front_desk["introduction"]["message"],
      not_understood: front_desk["not_understood"]["message"],
      clarification: front_desk["clarification"]["message"]
    }
  end

  @spec parse_variable(var :: map) :: Variable.t
  defp parse_variable(var) do
    %Variable{
      name: var["name"],
      values: var["values"],
      overrides: parse_variable_overrides(var["overrides"])
    }
  end

  @spec parse_variable_overrides(overrides :: nil | list) :: [Variable.Override.t]
  defp parse_variable_overrides(nil), do: []
  defp parse_variable_overrides(overrides) do
    overrides |> Enum.map(&parse_variable_override/1)
  end

  @spec parse_variable_override(override :: map) :: Variable.Override.t
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
      languages: skill["languages"]
    }
  end

  defp parse_skill(%{"type" => "keyword_responder"} = skill, bot_id) do
    %KeywordResponder{
      explanation: skill["explanation"],
      bot_id: bot_id,
      clarification: skill["clarification"],
      id: skill["id"],
      name: skill["name"],
      keywords: skill["keywords"],
      response: skill["response"],
      relevant: parse_expr(skill["relevant"])
    }
  end

  defp parse_skill(%{"type" => "scheduled_messages"} = skill, bot_id) do
    schedule_type = case skill["schedule_type"] do
      "since_last_incoming_message" -> :since_last_incoming_message
      "fixed_time" -> :fixed_time
    end

    %ScheduledMessages{
      id: skill["id"],
      bot_id: bot_id,
      name: skill["name"],
      schedule_type: schedule_type,
      relevant: parse_expr(skill["relevant"]),
      messages: skill["messages"] |> Enum.map(&(parse_scheduled_message(&1, schedule_type)))
    }
  end

  defp parse_skill(%{"type" => "survey"} = skill, bot_id) do
    {:ok, schedule, _} = skill["schedule"] |> DateTime.from_iso8601()
    choice_lists = skill["choice_lists"] |> Enum.map(&parse_survey_choice_list/1) |> Enum.into(%{})

    %Survey{
      id: skill["id"],
      bot_id: bot_id,
      name: skill["name"],
      schedule: schedule,
      relevant: parse_expr(skill["relevant"]),
      questions: skill["questions"] |> Enum.map(&(parse_survey_question(&1, choice_lists)))
    }
  end

  defp parse_scheduled_message(message, :since_last_incoming_message) do
    %DelayedMessage{
      delay: message["delay"],
      message: message["message"]
    }
  end

  defp parse_scheduled_message(message, :fixed_time) do
    {:ok, schedule, _} = message["schedule"] |> DateTime.from_iso8601()
    %FixedTimeMessage{
      schedule: schedule,
      message: message["message"]
    }
  end

  defp parse_survey_question(question, choice_lists) do
    question_type = case question["type"] do
      "integer" -> :integer
      "decimal" -> :decimal
      "text" -> :text
      "select_one" -> :select_one
      "select_many" -> :select_many
    end
    parse_survey_question(question_type, question, choice_lists)
  end

  defp parse_survey_question(question_type, question, choice_lists) when question_type == :select_one or question_type == :select_many do
    %SelectQuestion{
      type: question_type,
      choices: choice_lists[question["choices"]],
      name: question["name"],
      relevant: parse_expr(question["relevant"]),
      message: question["message"],
      constraint_message: question["constraint_message"],
      choice_filter: parse_expr(question["choice_filter"])
    }
  end

  defp parse_survey_question(question_type, question, _) do
    %InputQuestion{
      type: question_type,
      name: question["name"],
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
    %Choice{
      name: choice["name"],
      labels: choice["labels"],
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

  defp validate(bot) do
    with :ok <- validate_skill_id_uniqueness(bot)
    do
      {:ok, bot}
    else
      err -> err
    end
  end

  defp validate_skill_id_uniqueness(%{skills: skills}) do
    duplicated_skills = skills
    |> Enum.group_by(fn(skill) -> skill |> Skill.id end)
    |> Map.to_list()
    |> Enum.find(fn({_, skills}) -> Enum.count(skills) > 1 end)

    case duplicated_skills do
      nil -> :ok
      {id, _} -> {:error, "Duplicated skill (#{id})"}
    end
  end
end
