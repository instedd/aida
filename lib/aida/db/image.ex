defmodule Aida.DB.Image do
  use Ecto.Schema
  import Ecto.Changeset
  alias __MODULE__

  schema "images" do
    field :binary, :binary
    field :binary_type, :string
    field :source_url, :string
    field :bot_id, :binary_id
    field :session_id, :binary_id
    field :uuid, :binary_id, read_after_writes: true

    timestamps()
  end

  @doc false
  def changeset(%Image{} = image, attrs) do
    image
    |> cast(attrs, [:binary, :binary_type, :source_url, :bot_id, :session_id])
    |> validate_required([:binary, :binary_type, :source_url, :bot_id, :session_id])
  end
end
