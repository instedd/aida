defmodule Aida.Repo.Migrations.CreateImages do
  use Ecto.Migration

  def change do
    create table(:images) do
      add :binary, :binary
      add :binary_type, :string
      add :source_url, :string

      timestamps()
    end
  end
end
