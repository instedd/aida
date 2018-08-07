defmodule AidaWeb.SkillUsageView do
  use AidaWeb, :view
  alias AidaWeb.SkillUsageView

  def render("usage_summary.json", %{
        users_count: users_count,
        messages_sent: messages_sent,
        messages_received: messages_received
      }) do
    %{
      active_users: users_count,
      messages_sent: messages_sent,
      messages_received: messages_received
    }
  end

  def render("users_per_skill.json", %{skills: skills}) do
    render_many(skills, SkillUsageView, "usage_count.json")
  end

  def render("usage_count.json", %{skill_usage: skill_usage}) do
    %{skill_id: skill_usage.skill_id, count: skill_usage.count}
  end
end
