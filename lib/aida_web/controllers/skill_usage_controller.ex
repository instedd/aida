defmodule AidaWeb.SkillUsageController do
  use AidaWeb, :controller

  alias Aida.DB
  # alias Aida.DB.Bot
  # alias Aida.JsonSchema

  def users_per_period(conn, %{"period" => period}) do
    skill_usages = DB.list_skill_usages()
    render(conn, "users_per_period.json", skill_usages: skill_usages)
  end

  def users_per_skill(conn, %{"skill_id" => skill_id}) do
    skill_usages = DB.list_skill_usages()
    render(conn, "users_per_skill.json", skill_usages: skill_usages)
  end

end
