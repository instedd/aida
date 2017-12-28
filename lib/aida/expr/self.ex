defmodule Aida.Expr.Self do
  defstruct []

  defimpl Aida.Expr, for: __MODULE__ do
    def to_string(_self) do
      "."
    end
  end
end
