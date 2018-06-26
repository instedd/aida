defmodule Aida.Skill.ScheduledMessages do
  alias Aida.{Message, Skill, BotManager, Recurrence, Bot}
  alias Aida.DB.{Session, SkillUsage, MessageLog}
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

  defmodule RecurrentMessage do
    @type t :: %__MODULE__{
      recurrence: Recurrence.t,
      message: Aida.Bot.message
    }

    defstruct recurrence: nil,
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

  @doc """
  Find the overdue and next messages

  Given a `delay` in minutes, returns a tuple of two elements
  where the first one is the latest overdue message and the
  second one is the next message to be scheduled.

  Either elements of the tuple could be `nil`.
  """
  @spec find_enclosing_messages(t, number) :: {nil | DelayedMessage.t, nil | DelayedMessage.t}
  def find_enclosing_messages(skill, delay) do
    find_enclosing_messages(skill.messages, delay, nil)
  end

  defp find_enclosing_messages([], _delay, prev) do
    {prev, nil}
  end

  defp find_enclosing_messages([message | messages], delay, prev) do
    if message.delay > delay do
      {prev, message}
    else
      find_enclosing_messages(messages, delay, message)
    end
  end

  defimpl Aida.Skill, for: __MODULE__ do
    def init(%{schedule_type: :since_last_incoming_message, messages: messages} = skill, _bot) do
      messages = messages |> Enum.sort_by(&(&1.delay))
      %{skill | messages: messages}
    end

    def init(%{schedule_type: :fixed_time, messages: [message | _]} = skill, bot) do
      if DateTime.compare(message.schedule, DateTime.utc_now) == :gt do
        BotManager.schedule_wake_up(bot, skill, message.schedule)
      end
      skill
    end

    def init(%{schedule_type: :recurrent, messages: messages} = skill, bot) do
      messages
      |> Enum.with_index
      |> Enum.each(fn {message, index} ->
        next = message.recurrence |> Recurrence.next
        BotManager.schedule_wake_up(bot, skill, index |> to_string, next)
      end)
      skill
    end

    def init(skill, _bot), do: skill

    def clear_state(_skill, message), do: message

    defp send_message(skill, bot, session_id, content) do
      session = Session.get(session_id)
      message = Message.new("", bot, session)

      if Message.language(message) && Skill.is_relevant?(skill, message) do
        message = Message.respond(message, content)
        Bot.send_message(message)

        SkillUsage.log_skill_usage(bot.id, Skill.id(skill), session_id, false)
      end
    end

    def wake_up(%{schedule_type: :since_last_incoming_message} = skill, bot, session_id) when is_binary(session_id) do
      last_activity_ts = MessageLog.get_last_incoming(bot.id, session_id)
      if last_activity_ts do
        last_activity_delay = DateTime.diff(DateTime.utc_now, last_activity_ts)
        {current_message, next_message} = ScheduledMessages.find_enclosing_messages(skill, last_activity_delay / 60)

        if current_message do
          send_message(skill, bot, session_id, current_message.message)
        end

        if next_message do
          # Schedule for the next delayed message
          wake_up_ts = Timex.shift(last_activity_ts, minutes: next_message.delay)
          BotManager.schedule_wake_up(bot, skill, session_id, wake_up_ts)
        end
      end
    end

    def wake_up(%{schedule_type: :fixed_time, messages: [fixed_message | _]} = skill, bot, nil) do
      Session.session_ids_by_bot(bot.id)
      |> Enum.each(fn session_id ->
        send_message(skill, bot, session_id, fixed_message.message)
      end)
    end

    def wake_up(%{schedule_type: :recurrent, messages: messages} = skill, bot, message_index) do
      message_index = String.to_integer(message_index)
      recurrent_message = messages |> Enum.at(message_index)
      Session.session_ids_by_bot(bot.id)
      |> Enum.each(fn session_id ->
        send_message(skill, bot, session_id, recurrent_message.message)
      end)

      next = recurrent_message.recurrence |> Recurrence.next
      BotManager.schedule_wake_up(bot, skill, message_index |> to_string, next)
    end

    def wake_up(_skill, _bot, _data) do
      :ok
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

    def confidence(%ScheduledMessages{schedule_type: :since_last_incoming_message} = skill, message) do
      first_message_delay = skill.messages
        |> Enum.map(fn %DelayedMessage{delay: delay} -> delay end)
        |> Enum.min()
      wake_up_ts = Timex.shift(DateTime.utc_now, minutes: first_message_delay)

      BotManager.schedule_wake_up(message.bot, skill, message.session.id, wake_up_ts)

      0
    end

    def confidence(_skill, _message), do: 0

    def id(%{id: id}) do
      id
    end

    def relevant(skill), do: skill.relevant

    def uses_encryption?(_), do: false
  end
end
