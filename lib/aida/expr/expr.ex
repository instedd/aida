defprotocol Aida.Expr do
  def to_string(expr)
  defdelegate parse(code), to: Aida.Expr.Parser
end

defmodule Aida.Expr.Parser do
  def parse(code) do
    {:ok, tokens, _} = :expr_lexer.string(code |> String.to_charlist)
    {:ok, ast} = :expr_parser.parse(tokens)
    ast
  end
end
