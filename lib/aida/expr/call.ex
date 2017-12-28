defmodule Aida.Expr.Call do
  defstruct [:name, :args]

  defimpl Aida.Expr, for: __MODULE__ do
    def to_string(call) do
      "#{call.name}(#{call.args |> Enum.map(&Aida.Expr.to_string/1) |> Enum.join(", ")})"
    end

    def eval(call, context) do
      args = call.args |> Enum.map(&(Aida.Expr.eval(&1, context)))
      invoke(call.name, args)
    end

    defp invoke(:true, []), do: true
    defp invoke(:false, []), do: false

    defp invoke(:selected, [list, value]) do
      value in list
    end
  end
end
