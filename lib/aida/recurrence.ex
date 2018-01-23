defprotocol Aida.Recurrence do
  @spec next(t, DateTime.t) :: DateTime.t
  def next(recurrence, now \\ DateTime.utc_now)
end
