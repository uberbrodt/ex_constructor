# Constructor

An Elixir  library for declaratively defining structs with field-level conversions
and validations.

Check out the [docs](https://hexdocs.pm/constructor) to learn about all the
features.

## Installation

Add `constructor` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:constructor, "~> 1.0.0-rc.5"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/constructor](https://hexdocs.pm/constructor).

## Acknowledgments
This library was born from the lack of a lightweight and flexible validation library in Elixir.
However, the design of the `constructor/2` macro and indeed much of the functionality
is provided by the excellent [TypedStruct](https://github.com/ejpcmac/typed_struct) library.

