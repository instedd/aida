defmodule AidaWeb.SkillUsageView do
  use AidaWeb, :view
  alias AidaWeb.SkillUsageView

  def render("users_per_period.json", %{skill_usages: skill_usages}) do
    %{data: render_many(skill_usages, SkillUsageView, "user.json")}
  end

  def render("users_per_skill.json", %{skill_usages: skill_usages}) do
    %{data: render_many(skill_usages, SkillUsageView, "user.json")}
  end

  def render("user.json", %{skill_usage: skill_usage}) do
    %{bot_id: skill_usage.bot_id,
      user_id: skill_usage.user_id,
      last_usage: skill_usage.last_usage
    }
  end

end
