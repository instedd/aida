defmodule Aida.DB.SkillUsage do
  use Ecto.Schema
  alias Aida.{DB, Skill, Message}
  import Ecto.Changeset
  alias Aida.Ecto.Type.JSON
  alias __MODULE__
  require Logger

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "skill_usage" do
    field :bot_id, :binary_id
    field :user_id, :string
    field :last_usage, Ecto.Date
    field :skill_id, :string
    field :user_generated, :boolean, default: false

    timestamps()
  end

  @doc false
  def changeset(%SkillUsage{} = botStats, attrs) do
    botStats
    |> cast(attrs, [:bot_id, :user_id, :last_usage, :skill_id, :user_generated])
    |> validate_required([:bot_id, :user_id, :last_usage, :skill_id, :user_generated])
  end

  def log_skill_usage(skill, message, user_generated \\ true) do
    changeset = %{bot_id: skill.bot_id, user_id: message.session.id, last_usage: Date.utc_today(), skill_id: Skill.id(skill), user_generated: true}
    DB.create_skill_usage(changeset)
  end
end


