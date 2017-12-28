defmodule Aida.Expr.Arith do
  defstruct [:op, :left, :right]

  defimpl Aida.Expr, for: __MODULE__ do
    def to_string(arith) do
      "(#{arith.left |> Aida.Expr.to_string} #{arith.op} #{arith.right |> Aida.Expr.to_string})"
    end
  end
end
