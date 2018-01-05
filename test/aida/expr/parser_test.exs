defmodule Aida.Expr.ParserTest do
  use ExUnit.Case
  import Aida.Expr
  alias Aida.Expr.{Literal, Comparison, Boolean, Arith, Call, Variable, Self, ParseError}

  describe "parse" do
    test "literals" do
      assert parse("123") == literal(123)
      assert parse("'foo'") == literal("foo")
    end

    test "comparisons" do
      assert parse("1 = 2") == cmp(:=, literal(1), literal(2))
      assert parse("1 < 2") == cmp(:<, literal(1), literal(2))
      assert parse("1 <= 2") == cmp(:<=, literal(1), literal(2))
      assert parse("1 > 2") == cmp(:>, literal(1), literal(2))
      assert parse("1 >= 2") == cmp(:>=, literal(1), literal(2))
      assert parse("1 != 2") == cmp(:!=, literal(1), literal(2))
    end

    test "boolean operators" do
      assert parse("1 and 2") == bool(:and, literal(1), literal(2))
      assert parse("1 or 2") == bool(:or, literal(1), literal(2))
    end

    test "arithmetic operators" do
      assert parse("1 + 2") == arith(:+, literal(1), literal(2))
      assert parse("1 - 2") == arith(:-, literal(1), literal(2))
      assert parse("1 * 2") == arith(:*, literal(1), literal(2))
      assert parse("1 div 2") == arith(:div, literal(1), literal(2))
      assert parse("1 mod 2") == arith(:mod, literal(1), literal(2))
    end

    test "precedence" do
      assert parse("1 and 2 and 3") == bool(:and, bool(:and, literal(1), literal(2)), literal(3))
      assert parse("1 or 2 or 3") == bool(:or, bool(:or, literal(1), literal(2)), literal(3))
      assert parse("1 + 2 + 3") == arith(:+, arith(:+, literal(1), literal(2)), literal(3))
      assert parse("1 < 2 and 3 < 4") == bool(:and, cmp(:<, literal(1), literal(2)), cmp(:<, literal(3), literal(4)))
      assert parse("1 + 2 = 3 - 4") == cmp(:=, arith(:+, literal(1), literal(2)), arith(:-, literal(3), literal(4)))
    end

    test "parentheses" do
      assert parse("1 and (2 and 3)") == bool(:and, literal(1), bool(:and, literal(2), literal(3)))
    end

    test "variables" do
      assert parse("${foo}") == var("foo")
    end

    test "function calls" do
      assert parse("true()") == call(:true, [])
      assert parse("selected(${var}, 2)") == call(:selected, [var("var"), literal(2)])
    end

    test "self" do
      assert parse(".") == %Self{}
    end

    test "errors" do
      assert_raise ParseError, ~r/Invalid expression: '@@@'/, fn ->
        parse("@@@")
      end
    end
  end

  defp literal(value) when is_integer(value) do
    %Literal{type: :integer, value: value}
  end

  defp literal(value) when is_binary(value) do
    %Literal{type: :string, value: value}
  end

  defp cmp(op, left, right) do
    %Comparison{op: op, left: left, right: right}
  end

  defp bool(op, left, right) do
    %Boolean{op: op, left: left, right: right}
  end

  defp arith(op, left, right) do
    %Arith{op: op, left: left, right: right}
  end

  defp var(name) do
    %Variable{name: name}
  end

  defp call(name, args) do
    %Call{name: name, args: args}
  end
end
