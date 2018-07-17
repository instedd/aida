defmodule AidaWeb.SkillUsageController do
  use AidaWeb, :controller

  alias Aida.DB

  def usage_summary(conn, %{"bot_id" => bot_id, "period" => period}) do
    skill_usages = DB.active_users_per_bot_and_period(bot_id, period)

    messages = Enum.at(DB.get_bot_messages_per_day_for_period(bot_id, period), 0) || 0

    render(conn, "usage_summary.json", users_count: Enum.count(skill_usages), messages_sent: messages.sent_messages, messages_received: messages.received_messages)
  end

  def users_per_skill(conn, %{"bot_id" => bot_id, "period" => period}) do
    skill_usages = DB.skill_usages_per_user_bot_and_period(bot_id, period)

    render(conn, "users_per_skill.json", skills: skill_usages)
  end
end
