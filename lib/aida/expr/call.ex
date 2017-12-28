defmodule Aida.Expr.Call do
  defstruct [:name, :args]

  defimpl Aida.Expr, for: __MODULE__ do
    def to_string(call) do
      "#{call.name}(#{call.args |> Enum.map(&Aida.Expr.to_string/1) |> Enum.join(", ")})"
    end
  end
end
