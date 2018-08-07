defmodule Aida.DataTable do
  alias __MODULE__

  @type t :: %DataTable{
          name: String.t(),
          columns: [String.t()],
          data: [[String.t()]]
        }

  defstruct [:name, :columns, :data]

  def lookup(data_table_set, key, table_name, value_column) when is_list(data_table_set) do
    with {:ok, table} <- find_data_table(data_table_set, table_name) do
      table |> DataTable.lookup(key, value_column)
    end
  end

  def lookup(%DataTable{} = table, key, value_column) do
    with {:ok, column_index} <- find_table_column_index(table, value_column),
         {:ok, row} <- find_table_row(table, key, 0) do
      row |> Enum.at(column_index)
    end
  end

  defp find_data_table(data_tables, table_name) do
    case data_tables |> Enum.find(fn table -> table.name == table_name end) do
      nil -> {:error, "Table not found: #{table_name}"}
      table -> {:ok, table}
    end
  end

  defp find_table_column_index(table, value_column) do
    case table.columns |> Enum.find_index(fn column_name -> column_name == value_column end) do
      nil -> {:error, "Value column not found: #{value_column}"}
      index -> {:ok, index}
    end
  end

  defp find_table_row(table, key, key_column_index) do
    case table.data
         |> Enum.find(fn row -> compare_key(row |> Enum.at(key_column_index), key) end) do
      nil -> {:error, "Row not found with key: #{key}"}
      row -> {:ok, row}
    end
  end

  defp compare_key(k1, k2) when is_binary(k1) and is_number(k2) do
    case Float.parse(k1) do
      {value, ""} -> value == k2
      _ -> false
    end
  end

  defp compare_key(k1, k2) when is_number(k1) and is_binary(k2) do
    compare_key(k2, k1)
  end

  defp compare_key(k1, k2), do: k1 == k2
end
