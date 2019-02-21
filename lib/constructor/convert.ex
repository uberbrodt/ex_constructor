defmodule Constructor.Convert do
  @moduledoc false

  @doc """
  Converts integers, floats and atoms to an equivalent string representation. `nil` is converted to
  `""`
  """
  @spec to_string(any) :: any
  def to_string(v) do
    case v do
      nil -> ""
      x when is_binary(x) -> x
      x when is_integer(x) -> Integer.to_string(x)
      x when is_float(x) -> Float.to_string(x)
      x when is_atom(x) -> Atom.to_string(x)
      x -> x
    end
  rescue
    ArgumentError -> v
  end

  @spec to_string_or_nil(any) :: any
  def to_string_or_nil(v) do
    case v do
      nil -> nil
      other -> __MODULE__.to_string(other)
    end
  end

  def to_integer(v) do
    case v do
      nil -> 0
      "" -> 0
      x when is_binary(x) -> String.to_integer(x)
      x -> x
    end
  rescue
    ArgumentError -> v
  end

  def to_integer_or_nil(v) do
    case v do
      nil -> nil
      other -> to_integer(other)
    end
  end

  def to_float(v) do
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

  def to_float_or_nil(v) do
    case v do
      nil -> nil
      other -> to_float(other)
    end
  end

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
  end

  def to_boolean_or_nil(v) do
    case v do
      nil -> nil
      other -> to_boolean(other)
    end
  end

  def nil_to_list(v) do
    case v do
      nil -> []
      o -> o
    end
  end

  def to_atom(item) do
    case item do
      nil -> nil
      x when is_binary(x) -> String.to_atom(x)
      _ -> item
    end
  end

  def upcase_string(v) when is_binary(v) do
    String.upcase(v)
  end

  def upcase_string(v) do
    v
  end

  def empty_to_nil(v) do
    case v do
      "" -> nil
      0 -> nil
      0.0 -> nil
      [] -> nil
      nil -> nil
      other -> other
    end
  end

  @doc """
  converts an atom or a string to an
  """
  def to_enum_string(e) do
    e
    |> to_string_or_nil()
    |> empty_to_nil()
    |> upcase_string()

    case e do
      nil -> nil
      "" -> nil
      x when is_binary(x) -> x |> Macro.underscore() |> String.upcase()
      x when is_atom(x) -> x |> Atom.to_string() |> Macro.underscore() |> String.upcase()
      _ -> e
    end
  end
end
