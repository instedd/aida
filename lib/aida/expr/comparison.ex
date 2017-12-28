defmodule Aida.Expr.Comparison do
  defstruct [:op, :left, :right]

  defimpl Aida.Expr, for: __MODULE__ do
    def to_string(cmp) do
      "(#{cmp.left |> Aida.Expr.to_string} #{cmp.op} #{cmp.right |> Aida.Expr.to_string})"
    end

    def eval(cmp, context) do
      left = cmp.left |> Aida.Expr.eval(context)
      right = cmp.right |> Aida.Expr.eval(context)

      case cmp.op do
        := -> left == right
        :!= -> left != right
        :< -> left < right
        :<= -> left <= right
        :> -> left > right
        :>= -> left >= right
      end
    end
  end
end
