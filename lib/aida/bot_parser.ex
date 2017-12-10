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
    SelectQuestion,
    InputQuestion,
    ChoiceList,
    Choice,
    Variable,
    Channel.Facebook
  }

  @spec parse(id :: String.t, manifest :: map) :: {atom, Bot.t}
  def parse(id, manifest) do
    %Bot{
      id: id,
      languages: manifest["languages"],
      front_desk: parse_front_desk(manifest["front_desk"]),
      skills: manifest["skills"] |> Enum.map(&parse_skill/1),
      variables: manifest["variables"] |> Enum.map(&parse_variable/1),
      channels: manifest["channels"] |> Enum.map(&(parse_channel(id, &1)))
    }
    |> validate()
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
      values: var["values"]
    }
  end

  defp parse_skill(%{"type" => "language_detector"} = skill) do
    %LanguageDetector{
      explanation: skill["explanation"],
      languages: skill["languages"]
    }
  end

  defp parse_skill(%{"type" => "keyword_responder"} = skill) do
    %KeywordResponder{
      explanation: skill["explanation"],
      clarification: skill["clarification"],
      id: skill["id"],
      name: skill["name"],
      keywords: skill["keywords"],
      response: skill["response"]
    }
  end

  defp parse_skill(%{"type" => "scheduled_messages"} = skill) do
    %ScheduledMessages{
      id: skill["id"],
      name: skill["name"],
      schedule_type: skill["schedule_type"],
      messages: skill["messages"] |> Enum.map(&parse_delayed_message/1)
    }
  end

  defp parse_skill(%{"type" => "survey"} = skill) do
    {:ok, schedule, _} = skill["schedule"] |> DateTime.from_iso8601()
    %Survey{
      id: skill["id"],
      name: skill["name"],
      schedule: schedule,
      questions: skill["questions"] |> Enum.map(&parse_survey_question/1),
      choice_lists: skill["choice_lists"] |> Enum.map(&parse_survey_choice_list/1)
    }
  end

  defp parse_delayed_message(message) do
    %DelayedMessage{
      delay: message["delay"],
      message: message["message"]
    }
  end

  defp parse_survey_question(%{"type" => "select_one"} = question) do
    parse_select_survey_question(question)
  end
  defp parse_survey_question(%{"type" => "select_many"} = question) do
    parse_select_survey_question(question)
  end
  defp parse_survey_question(question) do
    %InputQuestion{
      type: question["type"],
      name: question["name"],
      message: question["message"]
    }
  end

  defp parse_select_survey_question(question) do
    %SelectQuestion{
      type: question["type"],
      choices: question["choices"],
      name: question["name"],
      message: question["message"]
    }
  end

  defp parse_survey_choice_list(choice_list) do
    %ChoiceList{
      name: choice_list["name"],
      choices: choice_list["choices"] |> Enum.map(&parse_survey_choice/1)
    }
  end

  defp parse_survey_choice(choice) do
    %Choice{
      name: choice["name"],
      labels: choice["labels"]
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
