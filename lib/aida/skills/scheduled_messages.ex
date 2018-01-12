defmodule Aida.Skill.ScheduledMessages do
  import Ecto.Query
  alias Aida.{Message, Repo, Channel, Session, Skill, BotManager, ChannelProvider, DB}
  alias Aida.DB.SkillUsage
  alias __MODULE__

  defmodule DelayedMessage do
    @type t :: %__MODULE__{
      delay: pos_integer,
      message: Aida.Bot.message
    }

    defstruct delay: 1,
              message: %{}
  end

  defmodule FixedTimeMessage do
    @type t :: %__MODULE__{
      schedule: DateTime.t,
      message: Aida.Bot.message
    }

    defstruct schedule: DateTime.utc_now,
              message: %{}
  end

  @type t :: %__MODULE__{
    id: String.t,
    bot_id: String.t,
    name: String.t,
    schedule_type: :since_last_incoming_message | :fixed_time,
    relevant: nil | Aida.Expr.t,
    messages: [DelayedMessage.t | FixedTimeMessage.t]
  }

  defstruct id: "",
            bot_id: "",
            name: "",
            schedule_type: :since_last_incoming_message,
            relevant: nil,
            messages: []

  def delay(skill, now \\ DateTime.utc_now)

  def delay(%{schedule_type: :since_last_incoming_message} = skill, _now) do
    message = skill.messages
      |> Enum.min_by(fn(message) -> message.delay end)

    delay = (div(message.delay, 2))
    delay = [delay, 24 * 60] |> Enum.min()
    delay = [delay, 20] |> Enum.max()

    :timer.minutes(delay)
  end

  def delay(%{schedule_type: :fixed_time, messages: [message | _]}, now) do
    DateTime.diff(message.schedule, now, :milliseconds)
  end

  def send_message(skill, bot, session_id, content) do
    session = Session.load(session_id)

    if Skill.is_relevant?(skill, session) do
      channel = ChannelProvider.find_channel(session_id)

      SkillUsage.log_skill_usage(skill.bot_id, Skill.id(skill), session_id, false)

      message = Message.new("", bot, session)
      message = message |> Message.respond(content)

      channel |> Channel.send_message(message.reply, session_id)
    end
  end

  defimpl Aida.Skill, for: __MODULE__ do
    def init(skill, bot) do
      delay = ScheduledMessages.delay(skill)
      if delay > 0 do
        BotManager.schedule_wake_up(bot, skill, delay)
      end

      skill
    end

    def wake_up(%{schedule_type: :since_last_incoming_message} = skill, bot) do
      skill_id = skill.id
      bot_id = bot.id
      reminder_deadlines = skill.messages
        |> Enum.map(fn(message) ->
          Timex.shift(DateTime.utc_now(), minutes: -message.delay)
        end)

      reminded_users = SkillUsage
        |> where([s], s.skill_id == ^skill_id and s.bot_id == ^bot_id)
        |> select([s], s.user_id)
        |> Repo.all()

      never_reminded = reminder_deadlines
        |> Enum.reduce((SkillUsage
          |> group_by([s], s.user_id)
          |> select([s], {s.user_id, max(s.last_usage)})
          |> where([s], not(s.user_id in ^reminded_users))
          |> where([s], s.bot_id == ^bot_id)), fn(deadline, query) ->
          query
          |> or_having([s], max(s.last_usage) < ^deadline)
        end)
        |> Repo.all()

      due_reminder = reminder_deadlines
        |> Enum.reduce((SkillUsage
          |> join(:inner, [s], t in SkillUsage, s.user_id == t.user_id and s.bot_id == t.bot_id)
          |> group_by([s, t], s.user_id)
          |> select([s, t], {s.user_id, max(s.last_usage), max(t.last_usage)})
          |> where([s, t], t.bot_id == ^bot_id)
          |> where([s, t], t.skill_id == ^skill_id)
          |> where([s, t], t.user_id in ^reminded_users)), fn(deadline, query) ->
          query
          |> or_having([s], max(s.last_usage) < ^deadline)
        end)
        |> Repo.all()

      never_reminded
        |> Enum.each(fn({user, last_usage}) ->
          ScheduledMessages.send_message(skill, bot, user, find_message_to_send(skill, last_usage))
        end)

      due_reminder
        |> Enum.each(fn({user, last_usage, _last_reminder}) ->
          ScheduledMessages.send_message(skill, bot, user, find_message_to_send(skill, last_usage))
        end)

      BotManager.schedule_wake_up(bot, skill, ScheduledMessages.delay(skill))
      :ok
    end

    def wake_up(%{schedule_type: :fixed_time, messages: [message | _]} = skill, bot) do
      DB.session_ids_by_bot(bot.id)
        |> Enum.each(fn session_id ->
          ScheduledMessages.send_message(skill, bot, session_id, message.message)
        end)
    end

    defp find_message_to_send(skill, last_usage) do
      {_, skill_message} = skill.messages
        |> Enum.map(fn(message) ->
          {Timex.shift(DateTime.utc_now(), minutes: -message.delay), message.message}
        end)
        |> Enum.filter(fn({deadline, _message}) ->
          DateTime.compare(deadline, Timex.to_datetime(last_usage)) != :lt
        end)
        |> Enum.min_by(fn({deadline, _message}) ->
          DateTime.to_unix(deadline, :millisecond)
        end)
      skill_message
    end

    def explain(%{}, message) do
      message
    end

    def clarify(%{}, message) do
      message
    end

    def put_response(%{}, message) do
      message
    end

    def confidence(%{}, _message) do
      0
    end

    def id(%{id: id}) do
      id
    end

    def relevant(skill), do: skill.relevant
  end
end
