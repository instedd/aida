defmodule Aida.DB.Session do
  use Ecto.Schema
  import Ecto.Changeset
  alias Aida.Ecto.Type.JSON
  alias __MODULE__

  @primary_key {:id, :string, autogenerate: false}
  @foreign_key_type :string
  schema "sessions" do
    field :data, JSON

    timestamps()
  end

  @doc false
  def changeset(%Session{} = session, attrs) do
    session
    |> cast(attrs, [:id, :data])
    |> validate_required([:id, :data])
  end
end
