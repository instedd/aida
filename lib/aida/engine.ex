defprotocol Aida.Engine do
  @spec confidence(message :: Aida.Message.t()) :: :ok
  def confidence(message)

  @spec update_training_set(engine :: Aida.Engine.t(), bot :: Aida.Bot.t()) :: :ok | {:error, %{}}
  def update_training_set(engine, bot)
end
