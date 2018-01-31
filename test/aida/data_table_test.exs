defmodule Aida.DataTableTest do
  alias Aida.DataTable
  use ExUnit.Case

  test "lookup in data table set" do
    data_tables = [
      %DataTable{
        name: "Distribution_days",
        columns: ["Location", "Day", "Distribution_place", "# of distribution posts"],
        data: [
          ["Kakuma 1", "Next Thursday", "In front of the square", 2],
          ["Kakuma 2", "Next Friday", "In front of the church", 1],
          ["Kakuma 3", "Next Saturday", "In front of the distribution centre", 3]
        ]
      }
    ]

    value = DataTable.lookup(data_tables, "Kakuma 1", "Distribution_days", "Day")
    assert value == "Next Thursday"
  end

  test "lookup with numbers in string column" do
    table = %DataTable{
      columns: ["key", "value"],
      data: [
        ["1", "One"],
        ["2.0", "Two"],
        ["3", "Three"],
        ["4.0", "Four"]
      ]
    }

    assert "One" == DataTable.lookup(table, 1, "value")
    assert "Two" == DataTable.lookup(table, 2, "value")
    assert "Three" == DataTable.lookup(table, 3.0, "value")
    assert "Four" == DataTable.lookup(table, 4.0, "value")
  end

  test "lookup with string in number column" do
    table = %DataTable{
      columns: ["key", "value"],
      data: [
        [1, "One"],
        [2.0, "Two"],
        [3, "Three"],
        [4.0, "Four"]
      ]
    }

    assert "One" == DataTable.lookup(table, "1", "value")
    assert "Two" == DataTable.lookup(table, "2", "value")
    assert "Three" == DataTable.lookup(table, "3.0", "value")
    assert "Four" == DataTable.lookup(table, "4.0", "value")
  end
end
