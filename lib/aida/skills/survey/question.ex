defprotocol Aida.Skill.Survey.Question do
  alias __MODULE__

  @spec valid_answer?(question :: Question.t(), message :: Aida.Message.t()) :: boolean
  def valid_answer?(question, message)

  @spec accept_answer(question :: Question.t(), message :: Aida.Message.t()) ::
          :error | {:ok, term}
  def accept_answer(question, message)

  @spec relevant(question :: Question.t()) :: Aida.Expr.t() | nil
  def relevant(question)

  @spec encrypt?(question :: Question.t()) :: boolean
  def encrypt?(question)
end
