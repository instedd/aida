defmodule Aida.Expr.Call do
  defstruct [:name, :args]

  defimpl Aida.Expr, for: __MODULE__ do
    def to_string(call) do
      "#{call.name}(#{call.args |> Enum.map(&Aida.Expr.to_string/1) |> Enum.join(", ")})"
    end

    def eval(call, context) do
      args = call.args |> Enum.map(&(Aida.Expr.eval(&1, context)))
      invoke(call.name, args, context)
    end

    defp invoke(:true, [], _), do: true
    defp invoke(:false, [], _), do: false

    defp invoke(:selected, [list, value], _) do
      value in list
    end

    defp invoke(function_name, args, context) do
      case context.functions |> Map.get(function_name) do
        nil -> raise Aida.Expr.UnknownFunctionError.exception(function_name)
        function -> function.(args)
      end
    end
  end
end
