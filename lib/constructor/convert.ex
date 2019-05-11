defmodule Constructor.Convert do
  @moduledoc """
  Functions in this module will typically perform a type conversion and then a validation.
  """
  alias Constructor.Validate


  @type error :: {:error, String.t()}


  @doc """
  Converts integers, floats and atoms to an equivalent string representation. `nil` is converted to
  `""`
  """
  @spec to_string(any) :: {:ok, String.t()} | error
  def to_string(v) do
    case v do
      nil -> ""
      x when is_binary(x) -> x
      x when is_integer(x) -> Integer.to_string(x)
      x when is_float(x) -> Float.to_string(x)
      x when is_atom(x) -> Atom.to_string(x)
      x -> x
    end
    |> Validate.is_string()
  end

  @spec to_string_or_nil(any) :: {:ok, String.t() | nil} | error
  def to_string_or_nil(v) do
    case v do
      nil -> {:ok, nil}
      other -> __MODULE__.to_string(other)
    end
  end

  @spec to_integer(any) :: {:ok, integer} | error
  def to_integer(v) do
    try do
      case v do
        nil -> 0
        "" -> 0
        x when is_binary(x) -> String.to_integer(x)
        x -> x
      end
    rescue
      ArgumentError -> v
    end
    |> Validate.is_integer()
  end

  @spec to_integer_or_nil(any) :: {:ok, integer | nil} | error
  def to_integer_or_nil(v) do
    case v do
      nil -> {:ok, nil}
      other -> to_integer(other)
    end
  end

  @spec to_float(any) :: {:ok, float} | error
  def to_float(v) do
    try do
      case v do
        0 -> 0.0
        nil -> 0.0
        "" -> 0.0
        "0" -> 0.0
        v when is_integer(v) -> v / 1
        v when is_float(v) -> v
        v when is_binary(v) -> String.to_float(v)
        v -> v
      end
    rescue
      ArgumentError -> v
    end
    |> Validate.is_float()
  end

  @spec to_float_or_nil(any) :: {:ok, float | nil} | error
  def to_float_or_nil(v) do
    case v do
      nil -> {:ok, nil}
      other -> to_float(other)
    end
  end

  @spec to_boolean(any) :: {:ok, boolean} | error
  def to_boolean(v) do
    case v do
      "true" -> true
      "false" -> false
      nil -> false
      "" -> false
      1 -> true
      0 -> false
      x -> x
    end
    |> Validate.is_boolean()
  end

  @spec to_boolean_or_nil(any) :: {:ok, boolean | nil} | error
  def to_boolean_or_nil(v) do
    case v do
      nil -> {:ok, nil}
      other -> to_boolean(other)
    end
  end

  @spec nil_to_list(any) :: {:ok, list} | error
  def nil_to_list(v) do
    case v do
      nil -> []
      o -> o
    end
    |> Validate.is_list()
  end

  @spec to_atom(any) :: {:ok, atom} | error
  def to_atom(item) do
    case item do
      nil -> nil
      x when is_binary(x) -> String.to_atom(x)
      _ -> item
    end
    |> Validate.is_atom()
  end

  @doc """
  Converts an atom such as  `:foo` to `"FOO"`.
  """
  def to_enum_string(e) do
    case e do
      nil -> nil
      "" -> nil
      x when is_binary(x) -> x |> Macro.underscore() |> String.upcase()
      x when is_atom(x) -> x |> Atom.to_string() |> Macro.underscore() |> String.upcase()
      _ -> e
    end
    |> Validate.is_string_or_nil()
  end
end
