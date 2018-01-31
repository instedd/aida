defprotocol Aida.Expr do
  def to_string(expr)
  def eval(expr, context \\ Aida.Expr.Context.new)
  defdelegate parse(code), to: Aida.Expr.Parser
end

defmodule Aida.Expr.ParseError do
  defexception [:message]

  def exception(message) do
    %__MODULE__{message: message}
  end
end

defmodule Aida.Expr.UnknownVariableError do
  defexception [:message]

  def exception(var_name) do
    %__MODULE__{message: "Could not find variable named '#{var_name}'"}
  end
end

defmodule Aida.Expr.UnknownFunctionError do
  defexception [:message]

  def exception(function_name) do
    %__MODULE__{message: "Could not find function named '#{function_name}'"}
  end
end

defmodule Aida.Expr.UnknownAttributeError do
  defexception [:message]

  def exception(attr_name) do
    %__MODULE__{message: "Could not find attribute named '#{attr_name}'"}
  end
end

defmodule Aida.Expr.Parser do
  def parse(code) do
    with {:ok, tokens, _} <- :expr_lexer.string(code |> String.to_charlist),
         {:ok, ast} <- :expr_parser.parse(tokens)
    do
      ast
    else
      _ -> raise Aida.Expr.ParseError.exception("Invalid expression: '#{code |> String.trim}'")
    end
  end
end
