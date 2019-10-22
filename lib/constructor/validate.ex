defmodule Constructor.Validate do
  @moduledoc """
  Common validations for struct fields.
  """
  @uuid_regex ~r/[a-f0-9]{8}-[a-f0-9]{4}-4[a-f0-9]{3}-[89aAbB][a-f0-9]{3}-[a-f0-9]{12}/

  @type error :: {:error, String.t()}

  @doc """
  Checks if input is a `t:Date.t/0`

  ## Examples

  ```
  iex> Constructor.Validate.is_date(%Date{year: 1999, month: 1, day: 1})
  {:ok, %Date{year: 1999, month: 1, day: 1}}

  iex> Constructor.Validate.is_date("foo")
  {:error, "must be a Date"}
  ```
  """
  @spec is_date(any) :: {:ok, Date.t()} | error
  def is_date(value) do
    case value do
      nil -> {:ok, value}
      %Date{} -> {:ok, value}
      _ -> {:error, "must be a Date"}
    end
  end

  @doc """
  Checks if a value is a boolean with `Kernel.is_boolean/1`

  ## Examples

  ```
  iex> Constructor.Validate.is_boolean(true)
  {:ok, true}

  iex> Constructor.Validate.is_boolean("true")
  {:error, "must be a boolean"}
  ```
  """
  @spec is_boolean(any) :: {:ok, boolean} | error
  def is_boolean(value) do
    case value do
      x when Kernel.is_boolean(x) -> {:ok, value}
      _ -> {:error, "must be a boolean"}
    end
  end

  @doc """
  Checks if a value is a `binary` with `Kernel.is_binary/1`.

  That means it will return `{:ok, value}` for both traditional Erlang `binary` and Elixir's
  `t:String.t/0`. This is usually what people mean when they say "string" in Elixir. However,
  `string` is a different type in Erlang, so make sure you make necessary conversions with another
  function.

  ## Examples

  ```
  iex> Constructor.Validate.is_string("foo")
  {:ok, "foo"}

  iex> Constructor.Validate.is_string(12)
  {:error, "must be a string"}
  ```
  """
  @spec is_string(any) :: {:ok, String.t()} | error
  def is_string(value) do
    case value do
      x when is_binary(x) -> {:ok, value}
      _ -> {:error, "must be a string"}
    end
  end

  @doc """
  The same as `is_string/1`, except that it will return `{:ok, nil}` if the `value` is `nil`.

  ## Examples

  ```
  iex> Constructor.Validate.is_string_or_nil(nil)
  {:ok, nil}
  ```
  """
  @spec is_string_or_nil(any) :: {:ok, String.t() | nil} | error
  def is_string_or_nil(value) do
    case value do
      nil -> {:ok, nil}
      other -> is_string(other)
    end
  end

  @doc """
  Checks that `value` is a list and that each value is a string.

  ## Examples

  ```
  iex> Constructor.Validate.is_string_list(["foo", 12, "bar"])
  {:error, "must be a list of strings"}

  iex> Constructor.Validate.is_string_list(["foo", "bar", "baz"])
  {:ok, ["foo", "bar", "baz"]}
  ```
  """
  @spec is_string_list(any) :: {:ok, list(String.t())} | error
  def is_string_list(value) do
    is_string_list(value, value)
  end

  def is_string_list([head | tail], value) do
    case head do
      v when is_binary(v) -> is_string_list(tail, value)
      _ -> {:error, "must be a list of strings"}
    end
  end

  def is_string_list([], v) do
    {:ok, v}
  end

  def is_string_list(_, _v) do
    {:error, "must be a list"}
  end

  @doc """
  Checks that `value` is an integer.

  ## Examples

  ```
  iex> Constructor.Validate.is_integer(12)
  {:ok, 12}

  iex> Constructor.Validate.is_integer("12")
  {:error, "must be an integer"}
  ```
  """
  @spec is_integer(any) :: {:ok, integer} | error
  def is_integer(value) do
    case value do
      x when Kernel.is_integer(x) -> {:ok, value}
      _ -> {:error, "must be an integer"}
    end
  end

  @doc """
  Checks that `value` is a float.

  ## Examples

  ```
  iex> Constructor.Validate.is_float(12.3)
  {:ok, 12.3}

  iex> Constructor.Validate.is_float(12)
  {:error, "must be a float"}
  ```
  """
  @spec is_float(any) :: {:ok, float} | error
  def is_float(value) do
    case value do
      x when Kernel.is_float(x) -> {:ok, value}
      :unchanged -> {:ok, value}
      _ -> {:error, "must be a float"}
    end
  end

  @doc """
  Checks that `value` is a list.

  ## Examples

  ```
  iex> Constructor.Validate.is_list(["foo", "bar"])
  {:ok, ["foo", "bar"]}

  iex> Constructor.Validate.is_list(%{foo: "bar"})
  {:error, "must be a list"}
  ```
  """
  @spec is_list(any) :: {:ok, list} | error
  def is_list(value) do
    case value do
      x when Kernel.is_list(x) -> {:ok, x}
      _ -> {:error, "must be a list"}
    end
  end

  @doc """
  Checks that `value` is an atom.

  ## Examples

  ```
  iex> Constructor.Validate.is_atom(:foo)
  {:ok, :foo}

  iex> Constructor.Validate.is_atom(%{foo: "bar"})
  {:error, "must be an atom"}
  ```
  """
  @spec is_atom(any) :: {:ok, atom} | error
  def is_atom(value) do
    case value do
      x when Kernel.is_atom(x) -> {:ok, x}
      _ -> {:error, "must be an atom"}
    end
  end

  @doc """
  Checks that `value` is a uuid.

  ## Examples

  ```
  iex> Constructor.Validate.is_uuid("8cd1939d-89ca-4927-9166-a221312a5712")
  {:ok, "8cd1939d-89ca-4927-9166-a221312a5712"}

  iex> Constructor.Validate.is_uuid("209klmas09k;")
  {:error, "must be a UUID"}
  ```
  """
  @spec is_uuid(any) :: {:ok, String.t()} | error
  def is_uuid(value) when is_binary(value) do
    case String.match?(value, @uuid_regex) do
      true -> {:ok, value}
      false -> {:error, "must be a UUID"}
    end
  end

  def is_uuid(_) do
    {:error, "must be a UUID"}
  end

  @doc """
  Checks that `value` is both a string, and not nonempty ("").

  ## Examples

  ```
  iex> Constructor.Validate.is_not_blank("a")
  {:ok, "a"}

  iex> Constructor.Validate.is_not_blank("")
  {:error, "must not be blank"}

  iex> Constructor.Validate.is_not_blank(12)
  {:error, "must be a string"}
  ```
  """
  @spec is_not_blank(any) :: {:ok, String.t()} | error
  def is_not_blank(value) do
    case value do
      "" -> {:error, "must not be blank"}
      x when is_binary(x) -> {:ok, x}
      _ -> {:error, "must be a string"}
    end
  end
end
