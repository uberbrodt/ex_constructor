defmodule Constructor.Validate do
  @moduledoc """
  Common validations for struct fields.
  """
  @uuid_regex ~r/[a-f0-9]{8}-[a-f0-9]{4}-4[a-f0-9]{3}-[89aAbB][a-f0-9]{3}-[a-f0-9]{12}/

  @type error :: {:error, String.t()}


  @spec is_date(any) :: {:ok, Date.t} | error
  def is_date(value) do
    case value do
      nil -> {:ok, value}
      %Date{} -> {:ok, value}
      _ -> {:error, "must be a Date"}
    end
  end

  @spec is_boolean(any) :: {:ok, boolean} | error
  def is_boolean(value) do
    case value do
      x when Kernel.is_boolean(x) -> {:ok, value}
      _ -> {:error, "must be a boolean"}
    end
  end

  @spec is_string(any) :: {:ok, String.t()} | error
  def is_string(value) do
    case value do
      x when is_binary(x) -> {:ok, value}
      _ -> {:error, "must be a string"}
    end
  end

  @spec is_string_or_nil(any) :: {:ok, String.t() | nil} | error
  def is_string_or_nil(value) do
    case value do
      nil -> {:ok, nil}
      other -> is_string(other)
    end
  end

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

  @spec is_integer(any) :: {:ok, integer} | error
  def is_integer(value) do
    case value do
      x when Kernel.is_integer(x) -> {:ok, value}
      _ -> {:error, "must be an integer"}
    end
  end

  @spec is_float(any) :: {:ok, float} | error
  def is_float(value) do
    case value do
      x when Kernel.is_float(x) -> {:ok, value}
      :unchanged -> {:ok, value}
      _ -> {:error, "must be a float"}
    end
  end

  @spec is_list(any) :: {:ok, list} | error
  def is_list(value) do
    case value do
      x when Kernel.is_list(x) -> {:ok, x}
      _ -> {:error, "must be a list"}
    end
  end

  @spec is_atom(any) :: {:ok, atom} | error
  def is_atom(value) do
    case value do
      x when Kernel.is_atom(x) -> {:ok, x}
      _ -> {:error, "must be an atom"}
    end
  end

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

  @spec is_nonempty_string(any) :: {:ok, String.t()} | error
  def is_nonempty_string(value) do
    case value do
      nil -> {:error, "is required"}
      "" -> {:error, "is required"}
      x when is_binary(x) -> {:ok, x}
      _ -> {:error, "must be a string"}
    end
  end
end
