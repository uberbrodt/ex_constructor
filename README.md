# Constructor

An Elixir DSL for defining and validating structs.


## Usage

  ```elixir 
  defmodule ConstructorExampleUser do
    use Constructor

    constructor do
      field :id, :integer, constructor: &is_integer/1, enforce: true
      field :role,  :user | :admin, constructor: &is_valid_role/1, enforce: true
      field :first_name, :string, default: "", constructor: &is_string/1
      field :last_name, :string, default: "", constructor: &is_string/1
    end

    def is_valid_role(value) do
      case value do
        :admin -> {:ok, value}
        :user -> {:ok, value}
        _ -> {:error, "invalid role!"}
      end
    end
  end

  iex> ConstructorExampleUser.new(id: "foo", role: :admin, first_name: 37)
  {:error, {:constructor, %{id: "must be an integer", first_name: "must be an integer"}}}

  iex> ConstructorExampleUser.new(id: 12, role: :admin, first_name: "Chris")
  {:ok, %ConstructorExampleUser{id: 12, first_name: "Chris", last_name: ""}}

  iex> ConstructorExampleUser.new!(id: 12, role: :admin, first_name: "Chris")
  %ConstructorExampleUser{id: 12, first_name: "Chris", last_name: ""}
  ```

Check out the [docs](https://hexdocs.pm/constructor) to learn more.

## Installation

Add `constructor` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:constructor, "~> 1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/constructor](https://hexdocs.pm/constructor).


## But why?

Before writing the first iteration of this, I was using [Vex](https://github.com/CargoSense/vex)
for projects that didn't have an Ecto dependency, or `Ecto.Changeset` if I did.
It worked, but there were a couple of issues.

1. Vex has some [performance issues](https://github.com/CargoSense/vex/pull/52)
   that seem difficult to resolve in a way that won't break existing users.
   More concerning, it seems like Vex is [without a clear maintainer](https://github.com/CargoSense/vex/issues/33). 
2. You can do most of what `Constructor` does with `Ecto.Changesets`, but you
   bring a lot of [ORM](https://en.wikipedia.org/wiki/Object-relational_mapping)
   baggage along with it. Much of it may not be applicable if your project is
   not using an RDBMS.
   `Constructor` provides a richer and more concise way of doing validations and
   type casting 

## Acknowledgments
This library was born from the lack of a lightweight and flexible validation library in Elixir.
However, the design of the `constructor/2` macro and indeed much of the functionality
is provided by the excellent [TypedStruct](https://github.com/ejpcmac/typed_struct) library.

## Existing TypedStruct users
If you already depend on TypedStruct, you will need to remove that dependency
from your mix.exs until the plugin system is released. You can track progress
[here](https://github.com/ejpcmac/typed_struct/issues/9)

