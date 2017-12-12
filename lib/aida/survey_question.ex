defprotocol Aida.SurveyQuestion do
  @spec valid_answer?(question :: Aida.SurveyQuestion.t, message :: Aida.Message.t) :: boolean
  def valid_answer?(question, message)

  @spec accept_answer(question :: Aida.SurveyQuestion.t, message :: Aida.Message.t) :: :error | {:ok, term}
  def accept_answer(question, message)
end
