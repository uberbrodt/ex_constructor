defmodule Constructor do
  @moduledoc ~S"""
  Constructor is a DSL for defining and validating structs.


  ## Introduction

  To illustrate, let's take a basic `User` struct you might have in your app.

  ```
  defmodule ConstructorExampleUser do
    @enforce_keys [:id, :role]
    @allowed_keys ["id", "role", "first_name", "last_name"]

    @type t :: %__MODULE__{
      id: integer,
      role: :user | :admin,
      first_name: String.t(),
      last_name: String.t()
    }

    defstruct [:id, :role, first_name: "", last_name: ""]

    def new(v) when is_map(v) do
      struct = v |> convert_to_struct()
      with :ok <- is_integer(struct.id),
        :ok <- is_valid_role(struct.role),
        :ok <- is_string(struct.first_name),
        :ok <- is_string(struct.last_name) do
          {:ok, struct}
      else
        {:error, e} -> {:error, {:constructor, e}}
      end
    end

    def map_to_struct(v) do
      mapped = Enum.map(v, fn {key, value} ->
        if Enum.any?(@allowed_keys, fn x -> x == key end) do
          {String.to_atom(key), v}
        else
          {key, v}
        end
      end)
      struct(__MODULE__, mapped)
    end

    def is_string(value) do
      case value do
        x when is_binary(x) -> :ok
        _ -> {:error, "must be a string"}
      end
    end

    def is_integer(value) do
      case value do
        x when Kernel.is_integer(x) -> :ok
        _ -> {:error, "must be an integer"}
      end
    end

    def is_valid_role(value) do
      case value do
        :admin -> :ok
        :user -> :ok
        _ -> {:error, "invalid role"}
      end
    end
  end
  ```

  Elixir code such as this is pretty standard in most projects (especially those without Ecto).
  It's explicit, and good for taking input from a user or deserializing a struct from JSON.
  But it has some flaws:

  1. It returns on the first validation failure, so the user will have to fix and submit again in
     order to find out if there's another error.
  2. You have duplication of field names in the `@type`, `defstruct` and `@allowed_keys` declarations.
     A real pain to change each time you add or remove a field, with the `@type` tending to fall out of
     sync with the rest of the module quickly.
  3. It's a lot of code! Some parts, such as `is_integer/1` and `is_string/1`, can easily apply across
     projects. A production-ready implementation of `map_to_struct/1` would need to be expanded to
     handle nested structs and lists, all of which needs to be tested.

  Constructor solves this problem by providing a `constructor/2` macro that allows you to define a
  field, typespecs, enforced keys, validations, and coercions all in a handful of lines. Here's how
  you would write the above struct with Constructor.


  ```
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
  ```

  Most of the underlying functionality for Constructor is provided by `:typed_struct`. The
  `TypedStruct.field/3` macro has been expanded to collect the `:constructor` option, which is than
  used by the generated `new/1` methods. I won't repeat the `TypedStruct` documentation here, but it's
  important to note that `constructor/2` should behave the same as `TypedStruct.typedstruct/2` in
  all respects that aren't Constructor specific.

  You can see that unlike our previous `new/1` method, this one will accept keyword lists as well as
  maps and return errors for multiple fields.

  ```
  iex> ConstructorExampleUser.new(id: "foo", role: :admin, first_name: 37)
  {:error, {:constructor, %{id: "must be an integer", first_name: "must be an integer"}}}

  iex> ConstructorExampleUser.new(id: 12, role: :admin, first_name: "Chris")
  {:ok, %ConstructorExampleUser{id: 12, first_name: "Chris", last_name: ""}}

  iex> ConstructorExampleUser.new!(id: 12, role: :admin, first_name: "Chris")
  %ConstructorExampleUser{id: 12, first_name: "Chris", last_name: ""}
  ```

  Any function that conforms to `t:constructor_fun/1` can be used in the `construct` field.
  Additionally, a `new/1` function can also be used to build out a nested struct. For example:

  ```
  defmodule ConstructorExampleAdmin do
    use Constructor

    constructor do
      field :id, :integer, constructor: &Validate.is_integer/1
      field :user, ConstructorExampleUser.t(), constructor: &ConstructorExampleUser.new/1
    end
  end

  iex> ConstructorExampleAdmin.new!(id: 22, user: %{id: 22, first_name: "Chris"})
  %ConstructorExampleAdmin{id: 22, user: %ConstructorExampleUser{id: 22, first_name: "Chris"}}
  ```
  """


  defmodule ConstructorException do
    @moduledoc false
    defexception message: "An error occured creating a struct"
  end

  @type new_opts :: [nil_to_empty: boolean]

  @typedoc """
  The `:constructor` option for the `TypedStruct.field/3` macro. The {m,f,a} will be used as
  arguments to `apply/3`. A list of 1-arity funs and/or MFA tuples is also valid.
  """
  @type constructor :: constructor_fun | {m :: module, f :: atom, a :: list(any)} | [constructor_fun | {module, atom, list(any)}]

  @typedoc """
  Custom functions to be used in `TypedStruct.field/3` should conform to this spec.
  """
  @type constructor_fun :: (field_item :: any -> field_item :: any | {:error, String.t()})

  @doc """
  See `c:new/2`
  """
  @callback new(input :: map | keyword | list(map)) ::
              {:ok, struct | list(struct) | nil} | {:error, {:constructor, map}}

  @doc """
  This function is generated by the `constructor/2` macro, and will convert `input` into the struct
  it defines.

  After it coerces `input` into the appropriate struct, it will call `c:before_construct/1`.
  If that is successful, all the `:constructor` options are evaluated. Each field is evaluated individually,
  and all errors will be collected and returned. Otherwise, `c:after_construct/1` is called and the
  result returned.

  ## Parameters
  - `input` - can be a map, a keyword list or a list of maps. Whichever it is will determine the
    return type.
  - `opts` - a keyword list of the following options:
    - `:nil_to_empty` - overrides what was set on `constructor/2`

  ## Returns
  If `input` is a map or keyword list, the return type will be `{:ok, module}`. If it is a list
  of maps, it will try and convert each element of the list to the the module, returning
  `{:ok, [module]}`.

  In the event of an error, `{:error, {:constructor, map}}` is returned. The `map` keys are
  the struct parameters and the values are a list of errors for that field.

  ```
    iex> ConstructorExampleUser.new(id: "foo", role: :admin, first_name: 37)
    {:error, {:constructor, %{id: "must be an integer", first_name: "must be an integer"}}}
  ```

  """
  @callback new(input :: map | keyword | list(map), opts :: new_opts) ::
              {:ok, struct | list(struct) | nil} | {:error, {:constructor, map}}

  @doc """
  See `c:new!/2`
  """
  @callback new!(input :: map | keyword | list(map) | nil) :: struct | [struct] | nil | no_return


  @doc """
  Same as `c:new/2`, but returns the untagged struct or raises a ConstructorException
  """
  @callback new!(input :: map | keyword | list(map | nil), opts :: new_opts) ::
              struct | [struct] | nil | no_return

  @doc """
  The callback can be used to modify an input to `c:new/2` before the constructor functions are
  called.
  """
  @callback before_construct(any) :: {:ok, any} | {:error, {:constructor, map}}

  @doc """
  This callback can be used to perform a complex, multi-field validation after all of the per-field
  validations have run.
  """
  @callback after_construct(struct) :: {:ok, any} | {:error, {:constructor, map}}

  defmacro __using__(_) do
    behaviour_mod = __MODULE__

    quote location: :keep do
      @behaviour unquote(behaviour_mod)
      import Constructor, only: [constructor: 1, constructor: 2]
    end
  end

  @doc """
  Declare a struct and other attributes, in conjunction with the `TypedStruct.field/3` macro.

  `Constructor.Validate` and `Constructor.Convert` are automatically imported for the scope of this call
  only.

  ## Examples

  ```
  defmodule Car
    constructor do
      # `:constructor` options are evaluated *after* `:default` or other options.
      field :make, String.t(), default: "", constructor: &is_string/1
      field :model, String.t(), constructor: {Validate, :is_string, []}
      # when a `:constructor` is defined as a MFA tuple, the field value from input is passed as the
      # 1st argument, with the arguments defined here appended.
      field :vin, String.t(), constructor: [&is_string/1, {CustomValidation, :min_length, [17]}]
    end
  end
  ```


  ## Opts
  *Note:* All opts that `TypedStruct.typedstruct/2` accepts can be passed here as well.

  - `:nil_to_empty` - Whenever `c:new/2` receives a `nil` argument, it will return an empty struct
    with defaults set.  If instead you would like to receive `nil` back, set this option to `false`.
  """
  @spec constructor(opts :: keyword) :: Macro.t()
  defmacro constructor(opts \\ [], do: block) do
    opts = Keyword.put(opts, :plugins, [Constructor.TypedStructPlugin])

    quote location: :keep do
      alias Constructor.{Convert, Validate}
      import Constructor.Convert
      import Constructor.Validate
      Module.register_attribute(__MODULE__, :constructors, accumulate: true)

      require TypedStruct
      TypedStruct.typedstruct(unquote(opts), do: unquote(block))

      def __constructors__, do: Enum.reverse(@constructors)

      Constructor._field_constructors()
      Constructor._default_impl(_opts)
      Constructor._new(unquote(opts))
      defoverridable before_construct: 1, after_construct: 1
      import Constructor.Convert, only: []
      import Constructor.Validate, only: []
    end
  end

  defmacro _default_impl(_opts) do
    quote do
      @impl Constructor
      def before_construct(struct) do
        convert_struct(struct)
      end

      @impl Constructor
      def after_construct(struct) do
        {:ok, struct}
      end

      defp convert_struct(%__MODULE__{} = struct) do
        {:ok, struct}
      end

      defp convert_struct(%{__struct__: s} = input) do
        {:ok, struct(__MODULE__, Map.from_struct(input))}
      end

      defp convert_struct(map) when is_map(map) do
        {:ok, struct(__MODULE__, Morphix.atomorphify!(map, key_strings()))}
      end

      defp convert_struct(x), do: {:ok, x}

      def key_strings do
        __keys__() |> Enum.map(&Atom.to_string/1)
      end
    end
  end

  defmacro _new(opts) when is_list(opts) do
    nil_to_empty_global = Keyword.get(opts, :nil_to_empty, true)

    quote do
      @impl Constructor
      def new!(v, opts \\ []) do
        case new(v, opts) do
          {:ok, result} ->
            result

          {:error, _} = e ->
            raise ConstructorException, inspect(e)
        end
      end

      @impl Constructor
      def new(value, opts \\ [])

      @impl Constructor
      def new(nil, opts) do
        nil_to_empty = Keyword.get(opts, :nil_to_empty, unquote(nil_to_empty_global))

        if nil_to_empty do
          new(%__MODULE__{})
        else
          {:ok, nil}
        end
      end

      def new([], opts) do
        {:ok, []}
      end

      @impl Constructor
      def new(list, opts) when is_list(list) do
        if Keyword.keyword?(list) do
          new(struct(__MODULE__, list), opts)
        else
          mapped =
            for map <- list do
              case new(map, opts) do
                {:ok, result} -> result
                other -> other
              end
            end

          errors =
            Enum.with_index(mapped)
            |> Enum.reduce(%{}, fn {item, idx}, acc ->
              case item do
                {:error, {:constructor, err}} -> Map.put(acc, idx, err)
                {:error, err} -> Map.put(acc, idx, err)
                _ -> acc
              end
            end)

          if Enum.empty?(errors) do
            {:ok, mapped}
          else
            {:error, {:constructor, errors}}
          end
        end
      end

      @impl Constructor
      def new(map, opts) when is_map(map) do
        with {:ok, struct} <- before_construct(map),
             {:ok, constructed} <- _field_constructors(struct),
             {:ok, after_constructed} <- after_construct(constructed) do
          {:ok, after_constructed}
        end
      end

      def new({:error, _} = e, _) do
        e
      end

      def new(badarg, _) do
        {:error, {:badarg, badarg}}
      end
    end
  end

  defmacro _field_constructors() do
    quote location: :keep do
      @spec _field_constructors(in_struct :: struct) :: {:ok, struct} | {:error, any}
      def _field_constructors(in_struct) do
        results =
          Enum.into(__constructors__(), [], fn {field_name, construct_fun} ->
            field = Map.get(in_struct, field_name)
            result = Constructor._exec_field_fun(construct_fun, field)

            {field_name, result}
          end)

        case Constructor._process_result(results, in_struct) do
          {:ok, struct} = x -> x
          {:error, errors} -> {:error, {:constructor, errors}}
        end
      end
    end
  end

  def _exec_field_fun(functions, field) when is_list(functions) do
    case Enum.reduce(functions, field, &process_field_funs/2) do
      {:error, _} = e -> e
      result -> {:ok, result}
    end
  end

  def _exec_field_fun({m, f, a}, field) do
    apply(m, f, [field | a])
  end

  def _exec_field_fun(fun, field) do
    fun.(field)
  end

  defp process_field_funs(_fun, {:error, _} = e) do
    e
  end

  defp process_field_funs(fun, accumulator) do
    case _exec_field_fun(fun, accumulator) do
      {:ok, field} -> field
      {:error, _} = e -> e
    end
  end

  def _process_result(results, struct) do
    do_process_result(results, struct, [])
  end

  defp do_process_result([], struct, errors) do
    if Enum.empty?(errors) do
      {:ok, struct}
    else
      {:error, Enum.into(errors, %{})}
    end
  end

  defp do_process_result([result | results], struct, errors) do
    case result do
      {field_name, {:error, {:constructor, error}}} ->
        do_process_result(results, struct, [{field_name, error} | errors])

      {field_name, {:error, error}} ->
        do_process_result(results, struct, [{field_name, error} | errors])

      {field_name, {:ok, v}} ->
        do_process_result(results, Map.put(struct, field_name, v), errors)
    end
  end
end
