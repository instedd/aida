defmodule Aida.DB.Bot do
  use Ecto.Schema
  import Ecto.Changeset
  alias Aida.Ecto.Type.JSON
  alias __MODULE__

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "bots" do
    field :manifest, JSON
    field :temp, :boolean, default: false

    timestamps()
  end

  @doc false
  def changeset(%Bot{} = bot, attrs) do
    bot
    |> cast(attrs, [:manifest, :temp])
    |> validate_required([:manifest])
  end
end
