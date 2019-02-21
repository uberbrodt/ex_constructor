defmodule Constructor.Construct do
  @moduledoc false
  alias Constructor.{Convert, Validate}

  def string(v) do
    converted = Convert.to_string(v)

    case Validate.is_string(converted) do
      :ok -> {:ok, converted}
      other -> other
    end
  end

  def integer(v) do
    converted = Convert.to_integer(v)

    case Validate.is_integer(converted) do
      :ok -> {:ok, converted}
      other -> other
    end
  end

  def uuid(v) do
    case v do
      x when is_binary(x) -> x
      nil -> UUID.uuid4()
      "" -> UUID.uuid4()
    end |> Validate.is_uuid()
  end
end
