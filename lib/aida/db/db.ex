defmodule Aida.DB do
  @moduledoc """
  The DB context.
  """

  import Ecto.Query, warn: false
  alias Aida.Repo
  alias Aida.PubSub

  alias Aida.DB.{Bot, SkillUsage, Session, MessagesPerDay, Image}

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
  def save_session(id, uuid, data) do
    %Session{}
      |> Session.changeset(%{id: id, data: data, uuid: uuid})
      |> Repo.insert(on_conflict: :replace_all, conflict_target: :id)
  end

  @doc """
  Returns the session for the given id. If the session does not exist, it returns `nil`.
  """
  # def get_session(id) do
  #   Session |> Repo.get(id)
  # end

  # def get_session_by_uuid(uuid) do
  #   Session |> Repo.get_by(uuid: uuid)
  # end

  @doc """
  Returns all the sessions for the given bot id. If there is none, it returns an empty array.
  """
  def sessions_by_bot(bot_id) do
    Session
      |> where(fragment("bot_id = ?", type(^bot_id, :binary_id)))
      |> Repo.all()
  end

  def session_ids_by_bot(bot_id) do
    Session
      |> where([s], s.bot_id == ^bot_id)
      |> select([s], s.id)
      |> Repo.all()
  end

  @doc """
  Deletes the session with the given id.
  """
  # def delete_session(id) do
  #   Session
  #     |> where([s], s.id == ^id)
  #     |> Repo.delete_all

  #   :ok
  # end

  def list_skill_usages do
    Repo.all(SkillUsage)
  end

  @doc """
  Returns the number of usages for each skill in the given period. If there is none, it returns an empty array.
  """
  def skill_usages_per_user_bot_and_period(bot_id, period, today \\ Date.utc_today()) do
    date = convert_period(period, today)

    SkillUsage
      |> group_by([s], [s.skill_id])
      |> select([s], %{skill_id: s.skill_id, count: count(s.user_id)})
      |> where([s], s.last_usage >= ^date)
      |> where([s], s.bot_id == ^bot_id)
      |> Repo.all()
  end

  @doc """
  Returns the user_ids that used a specific bot in the given period. If there is none, it returns an empty array.
  """
  def active_users_per_bot_and_period(bot_id, period, today \\ Date.utc_today()) do
    date = convert_period(period, today)

    SkillUsage
      |> distinct(true)
      |> select([s], {s.user_id})
      |> where([s], s.last_usage >= ^date)
      |> where([s], s.bot_id == ^bot_id)
      |> where([s], s.user_generated == true)
      |> Repo.all()
  end

  defp convert_period(period, today) do

    case period do
      "today" -> today
      "this_week" -> Date.add(today, -Date.day_of_week(today))
      "this_month" -> Date.add(today, -(today.day - 1))
      _ -> today
    end
  end

  @doc """
  Returns the skill usage for the given id. If the skill usage does not exist, it returns `nil`.
  """
  def get_skill_usage(id) do
    SkillUsage |> Repo.get(id)
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
  Creates or updates a skill_usage.

  ## Examples

      iex> create_or_update_skill_usage(%{field: value})
      {:ok, %SkillUsage{}}

      iex> create_or_update_skill_usage(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_or_update_skill_usage(attrs) do
    result = %SkillUsage{}
    |> SkillUsage.changeset(attrs)
    |> Repo.insert(on_conflict: [set: [last_usage: attrs.last_usage]], conflict_target: [:bot_id, :user_id, :skill_id, :user_generated])

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

  @doc """
  Creates or updates a messages_per_day.

  ## Examples

      iex> create_or_update_messages_per_day_received(%{field: value})
      {:ok, %MessagesPerDay{}}

      iex> create_or_update_messages_per_day_received(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_or_update_messages_per_day_received(attrs) do
    result = %MessagesPerDay{}
    |> MessagesPerDay.changeset(attrs)
    |> Repo.insert(on_conflict: [inc: [received_messages: 1]], conflict_target: [:bot_id, :day])

    result
  end

  @doc """
  Creates or updates a messages_per_day.

  ## Examples

      iex> create_or_update_messages_per_day_sent(%{field: value})
      {:ok, %MessagesPerDay{}}

      iex> create_or_update_messages_per_day_sent(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_or_update_messages_per_day_sent(attrs) do
    result = %MessagesPerDay{}
    |> MessagesPerDay.changeset(attrs)
    |> Repo.insert(on_conflict: [inc: [sent_messages: 1]], conflict_target: [:bot_id, :day])

    result
  end


  @doc """
  Returns the messages per day for the given id. If the messages per day does not exist, it returns `nil`.
  """
  def get_messages_per_day(id) do
    MessagesPerDay |> Repo.get(id)
  end

  def list_messages_per_day do
    Repo.all(MessagesPerDay)
  end

  @doc """
  Returns the messages per day for the given bot_id. If the messages per day does not exist, it returns `nil`.
  """
  def get_bot_messages_per_day_for_period(bot_id, period, today \\ Date.utc_today()) do
    date = convert_period(period, today)

    MessagesPerDay
      |> select([s], %{received_messages: fragment("coalesce(?, 0)", sum(s.received_messages)), sent_messages: fragment("coalesce(?, 0)", sum(s.sent_messages))})
      |> where([s], s.day >= ^date)
      |> where([s], s.bot_id == ^bot_id)
      |> Repo.all()
  end


  @doc """
  Gets a single image.

  Raises `Ecto.NoResultsError` if the Image does not exist.

  ## Examples

      iex> get_image!(123)
      %Image{}

      iex> get_image!(456)
      ** (Ecto.NoResultsError)

  """
  def get_image!(id), do: Repo.get_by!(Image, uuid: id)

  @doc """
  Gets a single image.

  Returns `nil` if the Image does not exist.
  """
  def get_image(id), do: Repo.get_by(Image, uuid: id)

  @doc """
  Creates an image.

  ## Examples

      iex> create_image(%{field: value})
      {:ok, %Image{}}

      iex> create_image(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_image(attrs \\ %{}) do
    result = %Image{}
    |> Image.changeset(attrs)
    |> Repo.insert()

    # case result do
    #   {:ok, image} -> PubSub.broadcast(image_created: image.id)
    #   _ -> :ignore
    # end

    result
  end


end
