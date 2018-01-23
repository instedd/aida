defmodule Aida.PubSub do
  @bot_changes_topic "bot_changes"
  @scheduler_topic "scheduler"

  def subscribe_bot_changes do
    Phoenix.PubSub.subscribe(__MODULE__, @bot_changes_topic)
  end

  def subscribe_scheduler do
    Phoenix.PubSub.subscribe(__MODULE__, @scheduler_topic)
  end

  def broadcast(bot_created: bot_id), do: broadcast(@bot_changes_topic, {:bot_created, bot_id})
  def broadcast(bot_updated: bot_id), do: broadcast(@bot_changes_topic, {:bot_updated, bot_id})
  def broadcast(bot_deleted: bot_id), do: broadcast(@bot_changes_topic, {:bot_deleted, bot_id})
  def broadcast(task_created: ts), do: broadcast(@scheduler_topic, {:task_created, ts})

  defp broadcast(topic, message) do
    Phoenix.PubSub.broadcast(__MODULE__, topic, message)
  end
end
