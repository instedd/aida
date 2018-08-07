defmodule Aida.Expr.BinaryOp do
  defstruct [:left, :op, :right]

  defimpl Aida.Expr, for: __MODULE__ do
    def to_string(bin) do
      "(#{bin.left |> Aida.Expr.to_string()} #{bin.op} #{bin.right |> Aida.Expr.to_string()})"
    end

    def eval(bin, context) do
      left = bin.left |> Aida.Expr.eval(context)
      right = bin.right |> Aida.Expr.eval(context)

      case bin.op do
        :and -> left and right
        :or -> left or right
        :+ -> left + right
        :- -> left - right
        :* -> left * right
        :div -> left / right
        :mod -> rem(left, right)
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
