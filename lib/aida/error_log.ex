defmodule Aida.ErrorLog do
  use Ecto.Schema
  import Ecto.Changeset
  alias __MODULE__
  alias Aida.{DB, Repo}

  @context_key :__error_log_context

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "error_logs" do
    belongs_to :bot, DB.Bot, type: :binary_id
    belongs_to :session, DB.Session, type: :binary_id
    field :skill_id, :string
    field :message, :string
    timestamps updated_at: false, type: :utc_datetime
  end

  @doc false
  def changeset(%ErrorLog{} = error_log, attrs) do
    error_log
    |> cast(attrs, [:bot_id, :session_id, :skill_id, :message])
    |> validate_required([:bot_id])
    |> foreign_key_constraint(:bot_id)
  end

  def write(message) do
    context = current_context()

    %ErrorLog{}
    |> changeset(%{
      bot_id: context[:bot_id],
      session_id: context[:session_id],
      skill_id: context[:skill_id],
      message: message
    })
    |> Repo.insert()
  end

  def current_context do
    Process.get(@context_key) || %{}
  end

  def push_context(vars) do
    old_context = current_context()
    new_context = Map.merge(old_context, Map.new(vars))
    Process.put(@context_key, new_context)

    old_context
  end

  def set_context(vars) do
    Process.put(@context_key, Map.new(vars))
  end

  defmacro context(vars, do: block) do
    quote do
      old_context = Aida.ErrorLog.push_context(unquote(vars))

      try do
        unquote(block)
      after
        Aida.ErrorLog.set_context(old_context)
      end
    end
  end

  defmacro __using__(_) do
    quote do
      require Aida.ErrorLog
      alias Aida.ErrorLog
    end
  end
end
