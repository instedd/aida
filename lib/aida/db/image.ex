defmodule Aida.DB.Image do
  use Ecto.Schema
  import Ecto.Changeset
  alias Aida.Ecto.Type.JSON
  alias __MODULE__

  schema "images" do
    field :binary, :binary
    field :binary_type, :string
    field :source_url, :string

    timestamps()
  end

  @doc false
  def changeset(%Image{} = image, attrs) do
    image
    |> cast(attrs, [:binary, :binary_type, :source_url])
    |> validate_required([:binary, :binary_type, :source_url])
  end
end
