defmodule AidaWeb.SkillUsageController do
  use AidaWeb, :controller

  alias Aida.DB
  # alias Aida.DB.Bot
  # alias Aida.JsonSchema

  def usage_summary(conn, %{"bot_id" => bot_id, "period" => period}) do
    skill_usages = DB.list_skill_usages()
    render(conn, "usage_summary.json", users_count: Enum.count(skill_usages), messages_sent: 22, messages_received: 55)
  end

  def users_per_skill(conn, %{"bot_id" => bot_id, "period" => period}) do
    skill_usages = DB.list_skill_usages()

    skills = [%{skill_id: 33, count: 32}, %{skill_id: 20, count: 6}, %{skill_id: 50, count: 66}]
    render(conn, "users_per_skill.json", skills: skills)
  end

end
