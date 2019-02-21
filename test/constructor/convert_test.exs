defmodule Constructor.ConvertTest do
  @moduledoc false
  use ExUnit.Case, async: true
  alias Constructor.Convert

  describe "to_string/1" do
    test ~s(nil is converted to "") do
      assert Convert.to_string(nil) == ""
    end

    test ~s("" remains "") do
      assert Convert.to_string("") == ""
    end

    test ~s("foobar" remains "foobar") do
      assert Convert.to_string("foobar") == "foobar"
    end

    test ~s(12 converted to  "12") do
      assert Convert.to_string(12) == "12"
    end

    test ~s(9.474 converted to  "9.474") do
      assert Convert.to_string(9.474) == "9.474"
    end

    test ~s(:foobar converted to "foobar") do
      assert Convert.to_string(:foobar) == "foobar"
    end

    test ~s(true converted to "true") do
      assert Convert.to_string(true) == "true"
    end

    test ~s('foobar' remains a charlist) do
      assert Convert.to_string('foobar') == 'foobar'
    end

    test ~s(["foo", "bar"] remains ["foo", "bar"]") do
      assert Convert.to_string(["foo", "bar"]) == ["foo", "bar"]
    end
  end

  describe "to_string_or_nil/1" do
    test ~s(nil remains nil) do
      assert Convert.to_string_or_nil(nil) == nil
    end

    test ~s("" remains "") do
      assert Convert.to_string_or_nil("") == ""
    end

    test ~s("foobar" remains "foobar") do
      assert Convert.to_string_or_nil("foobar") == "foobar"
    end

    test ~s(12 converted to  "12") do
      assert Convert.to_string_or_nil(12) == "12"
    end

    test ~s(9.474 converted to  "9.474") do
      assert Convert.to_string_or_nil(9.474) == "9.474"
    end

    test ~s(:foobar converted to "foobar") do
      assert Convert.to_string_or_nil(:foobar) == "foobar"
    end

    test ~s(true converted to "true") do
      assert Convert.to_string_or_nil(true) == "true"
    end

    test ~s('foobar' remains a charlist) do
      assert Convert.to_string_or_nil('foobar') == 'foobar'
    end

    test ~s(["foo", "bar"] remains ["foo", "bar"]") do
      assert Convert.to_string_or_nil(["foo", "bar"]) == ["foo", "bar"]
    end
  end

  describe "to_integer/1" do
    test ~s("12" is converted to 12) do
      assert Convert.to_integer("12") == 12
    end

    test ~s("" is converted to 0) do
      assert Convert.to_integer("") == 0
    end

    test ~s(nil is converted to 0) do
      assert Convert.to_integer(nil) == 0
    end

    test ~s("32.34" remains "32.34") do
      assert Convert.to_integer("32.34") == "32.34"
    end
  end

  describe "to_integer_or_nil" do
    test ~s("12" is converted to 12) do
      assert Convert.to_integer_or_nil("12") == 12
    end

    test ~s("" is converted to 0) do
      assert Convert.to_integer_or_nil("") == 0
    end

    test ~s(nil remains nil) do
      assert Convert.to_integer_or_nil(nil) == nil
    end

    test ~s("32.34" remains "32.34") do
      assert Convert.to_integer_or_nil("32.34") == "32.34"
    end
  end

  describe "to_float/1" do
    test "0 is converted to 0.0" do
      assert Convert.to_float(0) == 0.0
    end

    test "nil is converted to 0.0" do
      assert Convert.to_float(nil) == 0.0
    end

    test ~s("0" is converted to 0.0) do
      assert Convert.to_float("0") == 0.0
    end

    test ~s("0.0" is converted to 0.0) do
      assert Convert.to_float("0.0") == 0.0
    end

    test ~s(12 is converted to 12.0) do
      assert Convert.to_float(12) == 12.0
    end

    test ~s(83.21 remains 83.21) do
      assert Convert.to_float(83.21) == 83.21
    end
  end

  describe "to_float_or_nil/1" do
    test "nil is converted to nil" do
      assert Convert.to_float_or_nil(nil) == nil
    end

    test "0 is converted to 0.0" do
      assert Convert.to_float_or_nil(0) == 0.0
    end

    test ~s("0" is converted to 0.0) do
      assert Convert.to_float_or_nil("0") == 0.0
    end

    test ~s("0.0" is converted to 0.0) do
      assert Convert.to_float_or_nil("0.0") == 0.0
    end

    test ~s(12 is converted to 12.0) do
      assert Convert.to_float_or_nil(12) == 12.0
    end

    test ~s(83.21 remains 83.21) do
      assert Convert.to_float_or_nil(83.21) == 83.21
    end
  end

  describe "to_boolean/1" do
    test ~s("true" converted to true") do
      assert Convert.to_boolean("true") == true
    end

    test ~s("false" converted to false) do
      assert Convert.to_boolean("false") == false
    end

    test ~s(nil converted to false) do
      assert Convert.to_boolean(nil) == false
    end

    test ~s("" converted to false) do
      assert Convert.to_boolean("") == false
    end

    test ~s(1 converted to true) do
      assert Convert.to_boolean(1) == true
    end

    test ~s(0 converted to false) do
      assert Convert.to_boolean(0) == false
    end

    test ~s(0.0 remains 0.0) do
      assert Convert.to_boolean(0.0) == 0.0
    end

    test ~s(1.0 remains 1.0) do
      assert Convert.to_boolean(1.0) == 1.0
    end
  end

  describe "to_boolean_or_nil/1" do
    test ~s("true" converted to true") do
      assert Convert.to_boolean_or_nil("true") == true
    end

    test ~s("false" converted to false) do
      assert Convert.to_boolean_or_nil("false") == false
    end

    test ~s(nil converted to false) do
      assert Convert.to_boolean_or_nil(nil) == nil
    end

    test ~s("" converted to false) do
      assert Convert.to_boolean_or_nil("") == false
    end

    test ~s(1 converted to true) do
      assert Convert.to_boolean_or_nil(1) == true
    end

    test ~s(0 converted to false) do
      assert Convert.to_boolean_or_nil(0) == false
    end

    test ~s(0.0 remains 0.0) do
      assert Convert.to_boolean_or_nil(0.0) == 0.0
    end

    test ~s(1.0 remains 1.0) do
      assert Convert.to_boolean_or_nil(1.0) == 1.0
    end
  end

  describe "to_atom/1" do
    test "nil remains nil" do
      assert Convert.to_atom(nil) == nil
    end

    test ":foo remains :foo" do
      assert Convert.to_atom(:foo) == :foo
    end

    test ~s("foo" converted to :foo) do
      assert Convert.to_atom("foo") == :foo
    end
  end

  describe "nil_to_list/1" do
    test "nil remains nil" do
      assert Convert.nil_to_list(nil) == []
    end

    test "12 remains 12" do
      assert Convert.nil_to_list(12) == 12
    end

    test ~s("foo" remains "foo") do
      assert Convert.nil_to_list("foo") == "foo"
    end
  end

  describe "to_enum_string" do
    test ~s(:foo_bar converted to "FOO_BAR") do
      assert Convert.to_enum_string(:foo_bar) == "FOO_BAR"
    end

    test ~s("foo_bar" converted to "FOO_BAR") do
      assert Convert.to_enum_string("foo_bar") == "FOO_BAR"
    end

    test ~s("FooBar" converted to "FOO_BAR") do
      assert Convert.to_enum_string("FooBar") == "FOO_BAR"
    end

    test "nil remains nil" do
      assert Convert.to_enum_string(nil) == nil
    end

    test ~s("" converted to nil) do
      assert Convert.to_enum_string(nil) == nil
    end
  end
end
