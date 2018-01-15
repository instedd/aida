defmodule Aida.Scheduler.Task do
  alias __MODULE__
  alias Aida.Repo
  use Ecto.Schema
  import Ecto.Query
  import Ecto.Changeset

  schema "scheduler_tasks" do
    field :name, :string
    field :ts, :utc_datetime
    field :handler, Ecto.Atom

    timestamps()
  end

  def load(limit \\ 100) do
    Task
    |> order_by([t], t.ts)
    |> limit(^limit)
    |> Repo.all
  end

  def delete(task) do
    task |> Repo.delete
  end

  def changeset(%Task{} = task, attrs) do
    task
    |> cast(attrs, [:name, :ts, :handler])
    |> validate_required([:name, :ts, :handler])
    |> unique_constraint(:name)
  end

  def create(name, ts, handler) do
    %Task{}
    |> changeset(%{name: name, ts: ts, handler: handler})
    |> Aida.Repo.insert!(on_conflict: :replace_all, conflict_target: :name)
  end
end
