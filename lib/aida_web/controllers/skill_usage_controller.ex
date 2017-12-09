defmodule AidaWeb.SkillUsageController do
  use AidaWeb, :controller

  alias Aida.DB
  # alias Aida.DB.Bot
  # alias Aida.JsonSchema

  def users_per_period(conn, %{"bot_id" => bot_id, "period" => period}) do
    skill_usages = DB.list_skill_usages()
    render(conn, "users_per_period.json", users_count: Enum.count(skill_usages))
  end

  def users_per_skill(conn, %{"bot_id" => bot_id, "period" => period}) do
    skill_usages = DB.list_skill_usages()

    skills = [%{skill_id: 33, count: 32}, %{skill_id: 20, count: 6}, %{skill_id: 50, count: 66}]
    render(conn, "users_per_skill.json", skills: skills)
  end

end
