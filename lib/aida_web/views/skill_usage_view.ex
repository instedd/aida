defmodule AidaWeb.SkillUsageView do
  use AidaWeb, :view
  alias AidaWeb.SkillUsageView

  def render("users_per_period.json", %{users_count: users_count}) do
    %{active_users: users_count}
  end

  def render("users_per_skill.json", %{skills: skills}) do
    render_many(skills, SkillUsageView, "usage_count.json")
  end

  # def render("index.json", %{skill_usages: skill_usages}) do
  #   %{data: render_many(skill_usages, SkillUsageView, "skill_usage.json")}
  # end

  # def render("show.json", %{skill_usage: skill_usage}) do
  #   %{data: render_one(skill_usage, SkillUsageView, "skill_usage.json")}
  # end

  def render("usage_count.json", %{skill_usage: skill_usage}) do
    %{skill_id: skill_usage.skill_id,
      count: skill_usage.count
    }
  end

  def render("user.json", %{skill_usage: skill_usage}) do
    %{bot_id: skill_usage.bot_id,
      user_id: skill_usage.user_id,
      last_usage: skill_usage.last_usage
    }
  end

  # def render("skill_usage.json", %{skill_usage: skill_usage}) do
  #   %{bot_id: skill_usage.bot_id,
  #     user_id: skill_usage.user_id,
  #     last_usage: skill_usage.last_usage,
  #     skill_id: skill_usage.skill_id,
  #     user_generated: skill_usage.user_generated
  #   }
  # end
end
