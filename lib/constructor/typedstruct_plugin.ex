defmodule Constructor.TypedStructPlugin do
  @moduledoc false
  @behaviour TypedStruct.Plugin

  @impl true
  def field(mod, name, _type, opts) do
    constructor = opts[:constructor]

    if constructor != nil,
      do: Module.put_attribute(mod, :constructors, {name, constructor})
  end
end
