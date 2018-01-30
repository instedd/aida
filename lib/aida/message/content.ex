defprotocol Aida.Message.Content do
  @spec type(content :: Aida.Message.Content.t()) :: :text | :image | :unknown
  def type(content)

  @spec raw(content :: Aida.Message.Content.t()) :: String.t
  def raw(content)
end
