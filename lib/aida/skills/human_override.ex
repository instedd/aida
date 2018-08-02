defmodule Aida.Skill.HumanOverride do
  alias Aida.{Bot, Message, Message.TextContent, Skill.Utils}

  @type t :: %__MODULE__{
    explanation: Bot.message,
    clarification: Bot.message,
    id: String.t(),
    bot_id: String.t(),
    name: String.t(),
    keywords: %{},
    in_hours_response: %{},
    off_hours_response: %{},
    in_hours: %{},
    relevant: nil | Aida.Expr.t
  }

  defstruct explanation: %{},
            clarification: %{},
            id: "",
            bot_id: "",
            name: "",
            keywords: %{},
            in_hours_response: %{},
            off_hours_response: %{},
            in_hours: %{},
            relevant: nil

  defimpl Aida.Skill, for: __MODULE__ do
    def init(skill, _bot), do: skill

    def clear_state(_skill, message), do: message

    def wake_up(_skill, _bot, _data), do: :ok

    def explain(%{explanation: explanation}, message) do
      message |> Message.respond(explanation)
    end

    def clarify(%{clarification: clarification}, message) do
      message |> Message.respond(clarification)
    end

    defp weekday(datetime) do
      datetime
      |> DateTime.to_date
      |> Date.day_of_week
      |> Timex.day_shortname
    end

    def response(:in_hours, %{in_hours_response: in_hours_response}) do
      in_hours_response
    end

    def response(:off_hours, %{off_hours_response: off_hours_response}) do
      off_hours_response
    end

    def day_matches?(%{"day" => day}, weekday), do: String.downcase(day) == String.downcase(weekday)

    def parse_date(:beginning_of_day, day_reference), do: Timex.set(day_reference, [hour: 0, minute: 0, second: 0])
    def parse_date(:end_of_day, day_reference), do: Timex.set(day_reference, [hour: 23, minute: 59, second: 59])
    def parse_date(string, day_reference) do
      %{"hour" => hour, "minute" => minute } = Regex.named_captures(~r/(?<hour>\d+):(?<minute>\d+)/, string)
      {hour, _} = Integer.parse hour
      {minute, _} = Integer.parse minute
      Timex.set(day_reference, [hour: hour, minute: minute, second: 0])
    end

    def time_in_hours?(%{"since" => since, "until" => until}, timestamp) do
      timestamp |> Timex.between?(parse_date(since, timestamp), parse_date(until, timestamp), inclusive: true)
    end
    def time_in_hours?(%{"since" => since}, timestamp), do: time_in_hours?(%{"since" => since, "until" => :end_of_day}, timestamp)
    def time_in_hours?(%{"until" => until}, timestamp), do: time_in_hours?(%{"since" => :beginning_of_day, "until" => until}, timestamp)
    def time_in_hours?(%{}, timestamp), do: time_in_hours?(%{"since" => :beginning_of_day, "until" => :end_of_day}, timestamp)

    def in_hours?(timestamp, %{"hours" => hours, "timezone" => timezone}) do
      local_timestamp = Timex.Timezone.convert(timestamp, timezone)
      local_weekday = local_timestamp |> weekday
      is_in_hours = hours |> Enum.any?(fn(hour) -> (day_matches?(hour, local_weekday)) and time_in_hours?(hour, local_timestamp) end)

      if is_in_hours do
        :in_hours
      else
        :off_hours
      end
    end

    def message_response(%{in_hours: in_hours} = skill, timestamp) do
      in_hours?(timestamp, in_hours)
      |> response(skill)
    end

    def put_response(skill, %{bot: bot, timestamp: timestamp} = message) do
      response = message_response(skill, timestamp)
      Bot.notify(bot, :human_override, %{message: Message.text_content(message), bot_id: bot.id, session_id: message.session.id, name: Message.get_session(message, "first_name")})
      message |> Message.respond(response)
    end

    def confidence(%{keywords: keywords}, %{content: %TextContent{}} = message) do
      Utils.confidence_for_keywords(keywords, message)
    end

    def confidence(_, _), do: 0

    def id(%{id: id}) do
      id
    end

    def relevant(skill), do: skill.relevant

    def uses_encryption?(_), do: false
  end
end
