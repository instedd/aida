defmodule Aida.Expr.Boolean do
  defstruct [:op, :left, :right]

  defimpl Aida.Expr, for: __MODULE__ do
    def to_string(bool) do
      "(#{bool.left |> Aida.Expr.to_string} #{bool.op} #{bool.right |> Aida.Expr.to_string})"
    end
  end
end
