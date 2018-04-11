defmodule Aida.DB.SkillUsage do
  use Ecto.Schema
  alias Aida.DB
  import Ecto.Changeset
  alias __MODULE__
  require Logger

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "skill_usage" do
    field :bot_id, :binary_id
    field :user_id, :string
    field :last_usage, :date
    field :skill_id, :string
    field :user_generated, :boolean, default: false

    timestamps()
  end

  @doc false
  def changeset(%SkillUsage{} = skillUsage, attrs) do
    skillUsage
    |> cast(attrs, [:bot_id, :user_id, :last_usage, :skill_id, :user_generated])
    |> validate_required([:bot_id, :user_id, :last_usage, :skill_id, :user_generated])
  end

  def log_skill_usage(bot_id, skill_id, session_id, user_generated \\ true) do
    changeset = %{bot_id: bot_id, user_id: session_id, last_usage: Date.utc_today(), skill_id: skill_id, user_generated: user_generated}
    DB.create_or_update_skill_usage(changeset)
  end
end
