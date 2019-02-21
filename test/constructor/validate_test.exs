defmodule Constructor.ValidateTest do
  @moduledoc false
  use ExUnit.Case, async: true
  alias Constructor.Validate

  describe "is_boolean/1" do
    test ":false is true" do
      assert Validate.is_boolean(false) == {:ok, false}
    end

    test ":true is true" do
      assert Validate.is_boolean(true) == {:ok, true}
    end

    test ~s("true" is false) do
      assert Validate.is_boolean("true") == {:error, "must be a boolean"}
    end
  end

  describe "is_string/1" do
    test ~s("baz" is true) do
      assert Validate.is_string("baz") == {:ok, "baz"}
    end

    test "12 returns error" do
      assert Validate.is_string(12) == {:error, "must be a string"}
    end
  end

  describe "is_date/1" do
    test ~s("foo" is not a valid date) do
      assert Validate.is_date("foo") == {:error, "must be a Date"}
    end

    test "a %Date{} is a valid date" do
      assert Validate.is_date(~D[2018-01-01]) == {:ok, ~D[2018-01-01]}
    end
  end

  describe "is_string_list/1" do
    test "[] returns :ok" do
      assert Validate.is_string_list([]) == {:ok, []}
    end

    test ~s(["foo", "bar"] returns :ok) do
      assert Validate.is_string_list(["foo", "bar"]) == {:ok, ["foo", "bar"]}
    end

    test ~s(["foo", 12] returns {:error, {"must be a list of strings"}) do
      assert Validate.is_string_list(["foo", 12], "foo") ==
               {:error, "must be a list of strings"}
    end
  end

  describe "is_integer/1" do
    test "12 is :ok" do
      assert Validate.is_integer(12) == {:ok, 12}
    end

    test ~s("12" returns :error) do
      assert Validate.is_integer("12") == {:error, "must be an integer"}
    end
  end

  describe "is_float/1" do
    test "2.2 returns :ok" do
      assert Validate.is_float(2.2) == {:ok, 2.2}
    end

    test ~s("2.2" returns {:error, {"foo", "must be a float"}}) do
      assert Validate.is_float("2.2") == {:error, "must be a float"}
    end

    test ~s(2 returns {:error, {"foo", "must be a float"}}) do
      assert Validate.is_float(2) == {:error, "must be a float"}
    end
  end

  describe "is_uuid/2" do
    test "a UUID returns :ok" do
      uuid = UUID.uuid4()
      assert Validate.is_uuid(uuid) == {:ok, uuid}
    end

    test ~s("bar" returns {:error, "must be a UUID"}) do
      assert Validate.is_uuid("bar") == {:error, "must be a UUID"}
    end
  end
end
