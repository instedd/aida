defmodule Aida.DB do
  @moduledoc """
  The DB context.
  """

  import Ecto.Query, warn: false
  alias Aida.Repo
  alias Aida.PubSub

  alias Aida.DB.{Bot, SkillUsage, Session}

  @doc """
  Returns the list of bots.

  ## Examples

      iex> list_bots()
      [%Bot{}, ...]

  """
  def list_bots do
    Repo.all(Bot)
  end

  @doc """
  Gets a single bot.

  Raises `Ecto.NoResultsError` if the Bot does not exist.

  ## Examples

      iex> get_bot!(123)
      %Bot{}

      iex> get_bot!(456)
      ** (Ecto.NoResultsError)

  """
  def get_bot!(id), do: Repo.get!(Bot, id)

  @doc """
  Gets a single bot.

  Returns `nil` if the Bot does not exist.
  """
  def get_bot(id), do: Repo.get(Bot, id)

  @doc """
  Creates a bot.

  ## Examples

      iex> create_bot(%{field: value})
      {:ok, %Bot{}}

      iex> create_bot(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_bot(attrs \\ %{}) do
    result = %Bot{}
    |> Bot.changeset(attrs)
    |> Repo.insert()

    case result do
      {:ok, bot} -> PubSub.broadcast(bot_created: bot.id)
      _ -> :ignore
    end

    result
  end

  @doc """
  Updates a bot.

  ## Examples

      iex> update_bot(bot, %{field: new_value})
      {:ok, %Bot{}}

      iex> update_bot(bot, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_bot(%Bot{} = bot, attrs) do
    result = bot
    |> Bot.changeset(attrs)
    |> Repo.update()

    case result do
      {:ok, bot} -> PubSub.broadcast(bot_updated: bot.id)
      _ -> :ignore
    end

    result
  end

  @doc """
  Deletes a Bot.

  ## Examples

      iex> delete_bot(bot)
      {:ok, %Bot{}}

      iex> delete_bot(bot)
      {:error, %Ecto.Changeset{}}

  """
  def delete_bot(%Bot{} = bot) do
    result = Repo.delete(bot)

    case result do
      {:ok, bot} -> PubSub.broadcast(bot_deleted: bot.id)
      _ -> :ignore
    end

    result
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking bot changes.

  ## Examples

      iex> change_bot(bot)
      %Ecto.Changeset{source: %Bot{}}

  """
  def change_bot(%Bot{} = bot) do
    Bot.changeset(bot, %{})
  end

  @doc """
  Creates or updates the session data stored for the given session id
  """
  def save_session(id, data) do
    %Session{}
      |> Session.changeset(%{id: id, data: data})
      |> Repo.insert(on_conflict: :replace_all, conflict_target: :id)
  end

  @doc """
  Returns the session for the given id. If the session does not exist, it returns `nil`.
  """
  def get_session(id) do
    Session |> Repo.get(id)
  end

  @doc """
  Deletes the session with the given id
  """
  def delete_session(id) do
    Session
      |> where([s], s.id == ^id)
      |> Repo.delete_all

    :ok
  end

  def list_skill_usages do
    Repo.all(SkillUsage)
  end

  @doc """
  Creates a skill_usage.

  ## Examples

      iex> create_skill_usage(%{field: value})
      {:ok, %SkillUsage{}}

      iex> create_skill_usage(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_skill_usage(attrs \\ %{}) do
    result = %SkillUsage{}
    |> SkillUsage.changeset(attrs)
    |> Repo.insert()

    result
  end

  @doc """
  Updates a skill_usage.

  ## Examples

      iex> update_skill_usage(skill_usage, %{field: new_value})
      {:ok, %SkillUsage{}}

      iex> update_skill_usage(skill_usage, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_skill_usage(%SkillUsage{} = skill_usage, attrs) do
    result = skill_usage
    |> SkillUsage.changeset(attrs)
    |> Repo.update()

    result
  end
end
