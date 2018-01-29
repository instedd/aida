defmodule Aida.Bot do
  alias Aida.{FrontDesk, Variable, Message, Skill, Logger, Channel, DataTable}
  alias __MODULE__

  @type message :: map

  @type t :: %__MODULE__{
    id: String.t,
    languages: [String.t],
    front_desk: FrontDesk.t,
    skills: [Skill.t],
    variables: [Variable.t],
    channels: [Channel.t],
    public_keys: [binary],
    data_tables: [DataTable.t]
  }

  defstruct id: nil,
            languages: [],
            front_desk: %FrontDesk{},
            skills: [],
            variables: [],
            channels: [],
            public_keys: [],
            data_tables: []

  @spec init(bot :: t) :: {:ok, t}
  def init(bot) do
    skills = bot.skills
      |> Enum.map(fn(skill) ->
        Skill.init(skill, bot)
      end)

    {:ok, %{bot | skills: skills}}
  end

  @spec wake_up(bot :: t, skill_id :: String.t, data :: nil | String.t) :: :ok
  def wake_up(%Bot{} = bot, skill_id, data \\ nil) do
    find_skill(bot, skill_id)
      |> Skill.wake_up(bot, data)
  end

  @spec chat(bot :: t, message :: Message.t) :: Message.t
  def chat(%Bot{} = bot, %Message{} = message) do
    message
    |> reset_language_if_invalid(bot)
    |> choose_language_for_single_language_bot(bot)
    |> handle(bot)
    |> greet_if_no_response_and_language_was_set(bot, message)
    |> unset_session_new
  end

  defp unset_session_new(message) do
    %{message | session: %{message.session | is_new?: false}}
  end

  defp greet_if_no_response_and_language_was_set(message, bot, original_message) do
    lang_before = Message.language(original_message)
    lang_after = Message.language(message)

    if lang_before == nil && lang_after != nil && message.reply == [] do
      message
      |> FrontDesk.greet(bot)
    else
      message
    end
  end

  defp reset_language_if_invalid(message, bot) do
    if Message.language(message) not in bot.languages do
      Message.put_session(message, "language", nil)
    else
      message
    end
  end

  defp choose_language_for_single_language_bot(message, bot) do
    if !Message.language(message) && Enum.count(bot.languages) == 1 do
      Message.put_session(message, "language", bot.languages |> List.first)
    else
      message
    end
  end

  defp handle(message, bot) do
    skills_sorted = bot
      |> relevant_skills(message)
      |> Enum.map(&evaluate_confidence(&1, bot, message))
      |> Enum.reject(&is_nil/1)
      |> Enum.sort_by(fn skill -> skill.confidence end, &>=/2)

    case skills_sorted do
      [] ->
        if Message.new_session?(message) do
          message |> FrontDesk.greet(bot)
        else
          message |> FrontDesk.not_understood(bot)
        end
      skills ->
        higher_confidence_skill = Enum.at(skills, 0)

        difference = case Enum.count(skills) do
          1 -> higher_confidence_skill.confidence
          _ -> higher_confidence_skill.confidence - Enum.at(skills, 1).confidence
        end

        if threshold(bot) <= difference do
          Skill.respond(higher_confidence_skill.skill, message)
        else
          message |> FrontDesk.clarification(bot, Enum.map(skills, fn(skill) -> skill.skill end))
        end
    end
  end

  defp evaluate_confidence(skill, bot, message) do
    confidence = Skill.confidence(skill, message)
    case confidence do
      :threshold ->
        %{confidence: threshold(bot), skill: skill}
      confidence when confidence > 0 ->
        %{confidence: confidence, skill: skill}
      _ -> nil
    end
  end

  def relevant_skills(bot, message) do
    bot.skills
      |> Enum.filter(&Skill.is_relevant?(&1, message))
      |> Enum.filter(fn
        %Skill.LanguageDetector{} -> true
        _ -> Aida.Session.get(message.session, "language") != nil
      end)
  end

  defp find_skill(bot, skill_id) do
    skills = bot.skills
      |> Enum.filter(fn(skill) ->
        Skill.id(skill) == skill_id
      end)

    case skills do
      [skill] -> skill
      [] -> Logger.info "Skill not found #{skill_id}"
      _ -> Logger.info "Duplicated skill id #{skill_id}"
    end
  end

  def threshold(%Bot{front_desk: front_desk}) do
    front_desk |> FrontDesk.threshold
  end

  def lookup_var(%Bot{variables: variables}, message, key) do
    variable =
      variables
      |> Enum.find(fn var -> var.name == key end)

    if variable do
      variable |> Variable.resolve_value(message)
    end
  end

  def expr_context(bot, context, _options) do
    Aida.Expr.Context.add_function(context, "lookup", fn([key, table_name, value_column]) ->
      lookup_in_data_table(bot, table_name, key, value_column)
    end)
  end

  def lookup_in_data_table(%Bot{data_tables: data_tables}, table_name, key, value_column) do
    with  {:ok, table} <- find_data_table(data_tables, table_name),
          {:ok, column_index} <- find_table_column_index(table, value_column),
          {:ok, row} <- find_table_row(table, key, 0)
    do
      row |> Enum.at(column_index)
    else
      error ->
        Logger.warn(error)
        nil
    end
  end

  defp find_data_table(data_tables, table_name) do
    case data_tables |> Enum.find(fn(table) -> table.name == table_name end) do
      nil -> {:error, "Table not found"}
      table -> {:ok, table}
    end
  end

  defp find_table_column_index(table, value_column) do
    case table.columns |> Enum.find_index(fn(column_name) -> column_name == value_column end) do
      nil -> {:error, "Value column not found"}
      index -> {:ok, index}
    end
  end

  defp find_table_row(table, key, key_column_index) do
    case table.data |> Enum.find(fn(row) -> row |> Enum.at(key_column_index) == key end) do
      nil -> {:error, "Row not found"}
      row -> {:ok, row}
    end
  end
end
