defmodule Aida.Expr.Arith do
  defstruct [:op, :left, :right]

  defimpl Aida.Expr, for: __MODULE__ do
    def to_string(arith) do
      "(#{arith.left |> Aida.Expr.to_string} #{arith.op} #{arith.right |> Aida.Expr.to_string})"
    end

    def eval(arith, context) do
      left = arith.left |> Aida.Expr.eval(context)
      right = arith.right |> Aida.Expr.eval(context)

      case arith.op do
        :+ -> left + right
        :- -> left - right
        :* -> left * right
        :div -> left / right
        :mod -> rem(left, right)
      end
    end
  end
end
