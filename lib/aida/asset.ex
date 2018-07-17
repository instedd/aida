defmodule Aida.Asset do
  use Ecto.Schema
  import Ecto.Changeset

  alias Aida.{
    DB.Session,
    Ecto.Type.JSON,
    Repo
  }

  alias __MODULE__

  schema "assets" do
    field(:skill_id, :string)
    belongs_to(:session, Session, type: :binary_id)
    field(:data, JSON, default: %{})

    timestamps()
  end

  @type value :: Poison.Parser.t()
  @typep data :: %{required(String.t()) => value}

  @type t :: %__MODULE__{
          skill_id: String.t(),
          session_id: String.t(),
          data: data
        }

  @doc false
  def changeset(%__MODULE__{} = asset, attrs) do
    asset
    |> cast(attrs, [:skill_id, :session_id, :data])
    |> validate_required([:skill_id, :session_id, :data])
  end

  def create(attrs \\ %{}) do
    %Asset{}
    |> changeset(attrs)
    |> Repo.insert()
  end
end
