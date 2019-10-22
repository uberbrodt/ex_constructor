defmodule Constructor.ConvertTest do
  @moduledoc false
  use ExUnit.Case, async: true
  alias Constructor.Convert

  describe "to_string/1" do
    test ~s(nil is converted to "") do
      assert Convert.to_string(nil) == {:ok, ""}
    end

    test ~s("" remains "") do
      assert Convert.to_string("") == {:ok, ""}
    end

    test ~s("foobar" remains "foobar") do
      assert Convert.to_string("foobar") == {:ok, "foobar"}
    end

    test ~s(12 converted to  "12") do
      assert Convert.to_string(12) == {:ok, "12"}
    end

    test ~s(9.474 converted to  "9.474") do
      assert Convert.to_string(9.474) == {:ok, "9.474"}
    end

    test ~s(:foobar converted to "foobar") do
      assert Convert.to_string(:foobar) == {:ok, "foobar"}
    end

    test ~s(true converted to "true") do
      assert Convert.to_string(true) == {:ok, "true"}
    end

    test ~s('foobar' remains a charlist) do
      assert Convert.to_string('foobar') == {:error, "must be a string"}
    end

    test ~s(["foo", "bar"] returns an error") do
      assert Convert.to_string(["foo", "bar"]) == {:error, "must be a string"}
    end
  end

  describe "to_string_or_nil/1" do
    test ~s(nil remains nil) do
      assert Convert.to_string_or_nil(nil) == {:ok, nil}
    end

    test ~s("" remains "") do
      assert Convert.to_string_or_nil("") == {:ok, ""}
    end

    test ~s("foobar" remains "foobar") do
      assert Convert.to_string_or_nil("foobar") == {:ok, "foobar"}
    end

    test ~s(12 converted to  "12") do
      assert Convert.to_string_or_nil(12) == {:ok, "12"}
    end

    test ~s(9.474 converted to  "9.474") do
      assert Convert.to_string_or_nil(9.474) == {:ok, "9.474"}
    end

    test ~s(:foobar converted to "foobar") do
      assert Convert.to_string_or_nil(:foobar) == {:ok, "foobar"}
    end

    test ~s(true converted to "true") do
      assert Convert.to_string_or_nil(true) == {:ok, "true"}
    end

    test ~s('foobar' remains a charlist) do
      assert Convert.to_string_or_nil('foobar') == {:error, "must be a string"}
    end

    test ~s(["foo", "bar"] returns an error") do
      assert Convert.to_string_or_nil(["foo", "bar"]) == {:error, "must be a string"}
    end
  end

  describe "to_integer/1" do
    test ~s("12" is converted to 12) do
      assert Convert.to_integer("12") == {:ok, 12}
    end

    test ~s("" is converted to 0) do
      assert Convert.to_integer("") == {:ok, 0}
    end

    test ~s(nil is converted to 0) do
      assert Convert.to_integer(nil) == {:ok, 0}
    end

    test ~s("32.34" converts to 32") do
      assert Convert.to_integer("32.34") == {:error, "must be an integer"}
    end

    test ~s(32.34 converts to 32") do
      assert Convert.to_integer(32.34) == {:ok, 32}
    end

    test ~s("foo" returns an error) do
      assert Convert.to_integer("foo") == {:error, "must be an integer"}
    end
  end

  describe "to_integer_or_nil" do
    test ~s("12" is converted to 12) do
      assert Convert.to_integer_or_nil("12") == {:ok, 12}
    end

    test ~s("" is converted to 0) do
      assert Convert.to_integer_or_nil("") == {:ok, 0}
    end

    test ~s(nil remains nil) do
      assert Convert.to_integer_or_nil(nil) == {:ok, nil}
    end

    test ~s("32.34" fails validation") do
      assert Convert.to_integer_or_nil("32.34") == {:error, "must be an integer"}
    end
  end

  describe "to_float/1" do
    test "0 is converted to 0.0" do
      assert Convert.to_float(0) == {:ok, 0.0}
    end

    test "nil is converted to 0.0" do
      assert Convert.to_float(nil) == {:ok, 0.0}
    end

    test ~s("0" is converted to 0.0) do
      assert Convert.to_float("0") == {:ok, 0.0}
    end

    test ~s("0.0" is converted to 0.0) do
      assert Convert.to_float("0.0") == {:ok, 0.0}
    end

    test ~s(12 is converted to 12.0) do
      assert Convert.to_float(12) == {:ok, 12.0}
    end

    test ~s(83.21 remains 83.21) do
      assert Convert.to_float(83.21) == {:ok, 83.21}
    end

    test ~s([23] returns an error) do
      assert Convert.to_float([23]) == {:error, "must be a float"}
    end

    test "-12 converted to -12.0" do
      assert Convert.to_float(-12) == {:ok, -12.0}
    end

    test ~s("foo" returns an error) do
      assert Convert.to_float("foo") == {:error, "must be a float"}
    end
  end

  describe "to_float_or_nil/1" do
    test "nil is converted to nil" do
      assert Convert.to_float_or_nil(nil) == {:ok, nil}
    end

    test "0 is converted to 0.0" do
      assert Convert.to_float_or_nil(0) == {:ok, 0.0}
    end

    test ~s("0" is converted to 0.0) do
      assert Convert.to_float_or_nil("0") == {:ok, 0.0}
    end

    test ~s("0.0" is converted to 0.0) do
      assert Convert.to_float_or_nil("0.0") == {:ok, 0.0}
    end

    test ~s(12 is converted to 12.0) do
      assert Convert.to_float_or_nil(12) == {:ok, 12.0}
    end

    test ~s(83.21 remains 83.21) do
      assert Convert.to_float_or_nil(83.21) == {:ok, 83.21}
    end
  end

  describe "to_boolean/1" do
    test ~s("true" converted to true") do
      assert Convert.to_boolean("true") == {:ok, true}
    end

    test ~s("TRUE" converted to true") do
      assert Convert.to_boolean("TRUE") == {:ok, true}
    end

    test ~s("Tr123@" is an error") do
      assert Convert.to_boolean("Tr123@") == {:error, "must be a boolean"}
    end

    test ~s("false" converted to false) do
      assert Convert.to_boolean("false") == {:ok, false}
    end

    test ~s(nil converted to false) do
      assert Convert.to_boolean(nil) == {:ok, false}
    end

    test ~s("" converted to false) do
      assert Convert.to_boolean("") == {:ok, false}
    end

    test ~s(0 converted to false) do
      assert Convert.to_boolean(0) == {:ok, false}
    end

    test ~s(-5 converted to false) do
      assert Convert.to_boolean(-5) == {:ok, false}
    end

    test ~s(1 converted to true) do
      assert Convert.to_boolean(1) == {:ok, true}
    end

    test ~s(12 converted to true) do
      assert Convert.to_boolean(12) == {:ok, true}
    end

    test ~s(0.0 converted to false) do
      assert Convert.to_boolean(0.0) == {:ok, false}
    end

    test ~s(-5.0 converted to false) do
      assert Convert.to_boolean(-5.0) == {:ok, false}
    end

    test ~s(1.0 converted to true) do
      assert Convert.to_boolean(1.0) == {:ok, true}
    end

    test ~s(5.0 converted to true) do
      assert Convert.to_boolean(5.0) == {:ok, true}
    end

    test ~s(:true returns {:ok, true}) do
      assert Convert.to_boolean(true) == {:ok, true}
    end
  end

  describe "to_boolean_or_nil/1" do
    test ~s("true" converted to true") do
      assert Convert.to_boolean_or_nil("true") == {:ok, true}
    end

    test ~s("false" converted to false) do
      assert Convert.to_boolean_or_nil("false") == {:ok, false}
    end

    test ~s(nil converted to false) do
      assert Convert.to_boolean_or_nil(nil) == {:ok, nil}
    end

    test ~s("" converted to false) do
      assert Convert.to_boolean_or_nil("") == {:ok, false}
    end

    test ~s(1 converted to true) do
      assert Convert.to_boolean_or_nil(1) == {:ok, true}
    end

    test ~s(0 converted to false) do
      assert Convert.to_boolean_or_nil(0) == {:ok, false}
    end
  end

  describe "to_atom/1" do
    test "nil remains nil" do
      assert Convert.to_atom(nil) == {:ok, nil}
    end

    test ":foo remains :foo" do
      assert Convert.to_atom(:foo) == {:ok, :foo}
    end

    test ~s("foo" converted to :foo) do
      assert Convert.to_atom("foo") == {:ok, :foo}
    end
  end

  describe "to_existing_atom/1" do
    test "nil remains nil" do
      assert Convert.to_existing_atom(nil) == {:ok, nil}
    end

    test ":foo remains :foo" do
      assert Convert.to_existing_atom(:foo) == {:ok, :foo}
    end

    test ~s("foo" converted to :foo) do
      assert Convert.to_existing_atom("foo") == {:ok, :foo}
    end

    test ~s("23098.sd9234" is not an existing atom) do
      assert Convert.to_existing_atom("23098.sd9234") ==
               {:error, "23098.sd9234 is not an existing atom"}
    end
  end

  describe "nil_to_list/1" do
    test "nil converts to list" do
      assert Convert.nil_to_list(nil) == {:ok, []}
    end

    test "12 returns error" do
      assert Convert.nil_to_list(12) == {:error, "must be a list"}
    end

    test ~s("foo" returns error) do
      assert Convert.nil_to_list("foo") == {:error, "must be a list"}
    end
  end

  describe "to_enum_string" do
    test ~s(:foo_bar converted to "FOO_BAR") do
      assert Convert.to_enum_string(:foo_bar) == {:ok, "FOO_BAR"}
    end

    test ~s("foo_bar" converted to "FOO_BAR") do
      assert Convert.to_enum_string("foo_bar") == {:ok, "FOO_BAR"}
    end

    test ~s("FooBar" converted to "FOO_BAR") do
      assert Convert.to_enum_string("FooBar") == {:ok, "FOO_BAR"}
    end

    test "nil remains nil" do
      assert Convert.to_enum_string(nil) == {:ok, nil}
    end

    test ~s("" converted to nil) do
      assert Convert.to_enum_string(nil) == {:ok, nil}
    end

    test "12 causes an error" do
      assert Convert.to_enum_string(12) == {:error, "must be a string"}
    end
  end
end
