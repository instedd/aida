defmodule Aida.Expr.Boolean do
  defstruct [:op, :left, :right]

  defimpl Aida.Expr, for: __MODULE__ do
    def to_string(bool) do
      "(#{bool.left |> Aida.Expr.to_string} #{bool.op} #{bool.right |> Aida.Expr.to_string})"
    end

    def eval(bool, context) do
      left = bool.left |> Aida.Expr.eval(context)
      right = bool.right |> Aida.Expr.eval(context)

      case bool.op do
        :and -> left and right
        :or -> left or right
      end
    end
  end
end
