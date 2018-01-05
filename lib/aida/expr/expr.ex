defprotocol Aida.Expr do
  def to_string(expr)
  def eval(expr, context \\ %Aida.Expr.Context{})
  defdelegate parse(code), to: Aida.Expr.Parser
end

defmodule Aida.Expr.ParseError do
    defexception [:message]

    def exception(message) do
      %__MODULE__{message: message}
    end
  end

defmodule Aida.Expr.Parser do
  def parse(code) do
    with {:ok, tokens, _} <- :expr_lexer.string(code |> String.to_charlist),
         {:ok, ast} <- :expr_parser.parse(tokens)
    do
      ast
    else
      _ -> raise Aida.Expr.ParseError.exception("Invalid expression: '#{code}'")
    end
  end
end
