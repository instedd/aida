defmodule Aida.Expr.ParserTest do
  use ExUnit.Case
  import Aida.Expr
  alias Aida.Expr.{Literal, BinaryOp, UnaryOp, Call, Variable, Self, Attribute, ParseError}

  describe "parse" do
    test "literals" do
      assert parse("123") == literal(123)
      assert parse("-123") == literal(-123)
      assert parse("'foo'") == literal("foo")
      assert parse(~s("foo")) == literal("foo")
      assert parse("“foo”") == literal("foo")
      assert parse("‘foo’") == literal("foo")
    end

    test "comparisons" do
      assert parse("1 = 2") == binop(literal(1), :=, literal(2))
      assert parse("1 < 2") == binop(literal(1), :<, literal(2))
      assert parse("1 <= 2") == binop(literal(1), :<=, literal(2))
      assert parse("1 > 2") == binop(literal(1), :>, literal(2))
      assert parse("1 >= 2") == binop(literal(1), :>=, literal(2))
      assert parse("1 != 2") == binop(literal(1), :!=, literal(2))
    end

    test "boolean operators" do
      assert parse("1 and 2") == binop(literal(1), :and, literal(2))
      assert parse("1 or 2") == binop(literal(1), :or, literal(2))
    end

    test "arithmetic operators" do
      assert parse("1 + 2") == binop(literal(1), :+, literal(2))
      assert parse("1 - 2") == binop(literal(1), :-, literal(2))
      assert parse("1 * 2") == binop(literal(1), :*, literal(2))
      assert parse("1 div 2") == binop(literal(1), :div, literal(2))
      assert parse("1 mod 2") == binop(literal(1), :mod, literal(2))
      assert parse("- 2") == unaryop(:-, literal(2))
    end

    test "precedence" do
      assert parse("1 and 2 and 3") == binop(binop(literal(1), :and, literal(2)), :and, literal(3))
      assert parse("1 or 2 or 3") == binop(binop(literal(1), :or, literal(2)), :or, literal(3))
      assert parse("1 + 2 + 3") == binop(binop(literal(1), :+, literal(2)), :+, literal(3))
      assert parse("1 * 2 + 3 * 4") == binop(binop(literal(1), :*, literal(2)), :+, binop(literal(3), :*, literal(4)))
      assert parse("1 < 2 and 3 < 4") == binop(binop(literal(1), :<, literal(2)), :and, binop(literal(3), :<, literal(4)))
      assert parse("1 + 2 = 3 - 4") == binop(binop(literal(1), :+, literal(2)), :=, binop(literal(3), :-, literal(4)))
    end

    test "parentheses" do
      assert parse("1 and (2 and 3)") == binop(literal(1), :and, binop(literal(2), :and, literal(3)))
    end

    test "variables" do
      assert parse("${foo}") == var("foo")
    end

    test "variables with uppercase in first position" do
      assert parse("${Foo}") == var("Foo")
    end

    test "variables with uppercase in any position" do
      assert parse("${fOo}") == var("fOo")
    end

    test "variables with underscore in first position" do
      assert parse("${_foo}") == var("_foo")
    end

    test "variables with underscore in any position" do
      assert parse("${foo_bar}") == var("foo_bar")
    end

    test "variables with digits in valid position (every position but first one)" do
      assert parse("${foo1}") == var("foo1")
    end

    test "variables with uppercase, digits and underscores" do
      assert parse("${FoO_Bar_123}") == var("FoO_Bar_123")
    end

    test "attributes" do
      assert parse("foo") == attr("foo")
    end

    test "function calls" do
      assert parse("true()") == call(:true, [])
      assert parse("selected(${var}, 2)") == call(:selected, [var("var"), literal(2)])
    end

    test "custom function calls" do
      assert parse("foo(${var}, 2)") == call("foo", [var("var"), literal(2)])
    end

    test "self" do
      assert parse(".") == %Self{}
    end

    test "errors" do
      assert_raise ParseError, ~r/Invalid expression: '@@@'/, fn ->
        parse("@@@")
      end
    end

    test "error when variable starts with digit" do
      assert_raise ParseError, "Invalid expression: '${1foo}'", fn ->
        parse("${1foo}")
      end
    end
  end

  defp literal(value) when is_integer(value) do
    %Literal{type: :integer, value: value}
  end

  defp literal(value) when is_binary(value) do
    %Literal{type: :string, value: value}
  end

  defp binop(left, op, right) do
    %BinaryOp{left: left, op: op, right: right}
  end

  defp unaryop(op, value) do
    %UnaryOp{op: op, value: value}
  end

  defp var(name) do
    %Variable{name: name}
  end

  defp call(name, args) do
    %Call{name: name, args: args}
  end

  defp attr(name) do
    %Attribute{name: name}
  end
end
