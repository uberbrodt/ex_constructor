defmodule Constructor.TypedStructPlugin do
  @moduledoc false
  @behaviour TypedStruct.Plugin

  @impl true
  def field(mod, name, _type, opts) do
    validation = opts[:validation]
    conversion = opts[:conversion]
    constructor = opts[:constructor]

    if validation != nil && constructor == nil,
      do: Module.put_attribute(mod, :validations, {name, validation})

    if conversion != nil && constructor == nil,
      do: Module.put_attribute(mod, :conversions, {name, conversion})

    if constructor != nil,
      do: Module.put_attribute(mod, :constructors, {name, constructor})
  end
end
