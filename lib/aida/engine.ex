defprotocol Aida.Engine do
  @spec confidence(message :: Aida.Message.t()) :: :ok
  def confidence(message)
end
