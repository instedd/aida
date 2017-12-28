defmodule Aida.Expr.Comparison do
  defstruct [:op, :left, :right]

  defimpl Aida.Expr, for: __MODULE__ do
    def to_string(cmp) do
      "(#{cmp.left |> Aida.Expr.to_string} #{cmp.op} #{cmp.right |> Aida.Expr.to_string})"
    end
  end
end
