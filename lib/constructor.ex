defmodule Constructor do
  @moduledoc ~S"""
  Constructor is a DSL for defining and validating structs.
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

  Most of the underlying functionality for Constructor is provided by the `:typed_struct` library.
  The `TypedStruct.field/3` macro has been expanded to collect the `:constructor` option, which is
  than used by the generated `new/1` methods. I won't repeat the `TypedStruct` documentation here,
  but it's important to note that `constructor/2` should behave the same as `TypedStruct.typedstruct/2`
  in all respects that aren't Constructor specific.

  You can see that unlike our previous `new/1` method, this one will accept keyword lists as well as
  maps and return errors for multiple fields.

  ```
  iex> ConstructorExampleUser.new(id: "foo", role: :admin, first_name: 37)
  {:error, {:constructor, %{id: "must be an integer", first_name: "must be a string"}}}

  iex> ConstructorExampleUser.new(id: 12, role: :admin, first_name: "Chris")
  {:ok, %ConstructorExampleUser{id: 12, first_name: "Chris", last_name: ""}}

  iex> ConstructorExampleUser.new!(id: 12, role: :admin, first_name: "Chris")
  %ConstructorExampleUser{id: 12, first_name: "Chris", last_name: ""}
  ```

  Any function that conforms to `t:constructor_fun/0` can be used in the `construct` field.
  Additionally, a `c:new/1` function can also be used to build out a nested struct. For example:

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

  ## Enforce Keys
  If you're defining a struct with the `enforce: true` option, you'll also want to set the
  `check_keys: true` option in your `constructor` call. Note that this will cause `c:new/2` to raise
  a `KeyError` if a key that is undefined on the struct is passed as input.
  ## Custom Validation Functions

  Custom validation functions will need to confrom to the `t:constructor/0` typespec. The test suite
  has many examples.

  ## Optional Callbacks

  `c:before_construct/1` and `c:after_construct/1` can be implemented if you need to work with the
  entire input at once. If the input was a list of maps, the callbacks will be called for each list
  value.

    - `c:before_construct/1` will be called before anything else, so it allows you to manipulate the
      raw input before the rest of Constructor works on it.
    - `c:after_construct/1` will be called last, after everything else. It's good for doing multi-field
      validatons after the data has been converted and validated.
  """

  defmodule Exception do
    @moduledoc """
    Raised from `c:Constructor.new!/2`
    """
    defexception message: "An error occured creating a struct"
  end

  @type new_opts :: [nil_to_empty: boolean, check_keys: boolean]

  @typedoc """
  The `:constructor` option for the `TypedStruct.field/3` macro.

  The first form is a 1-arity function capture. The {m,f,a} form will be used as arguments to
  `apply/3`. This will allow use of N-arity functions, because the field value will always be passed
  as a first argument, with the provided args appended.  A list of 1-arity funs and/or MFA tuples is
  also valid.
  """
  @type constructor ::
          constructor_fun
          | {m :: module, f :: atom, a :: list(any)}
          | [constructor_fun | {module, atom, list(any)}]

  @typedoc """
  Custom functions to be used in `TypedStruct.field/3` should conform to this spec.
  """
  @type constructor_fun ::
          (field_item :: any ->
             field_item :: {:ok, any} | {:error, String.t()} | {:error, {:constructor, any}})

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
    - `:check_keys` - overrides what was set on `constructor/2`

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
  Same as `c:new/2`, but returns the untagged struct or raises a Constructor.Exception
  """
  @callback new!(input :: map | keyword | list(map | nil), opts :: new_opts) ::
              struct | [struct] | nil | no_return

  @doc """
  This callback runs before everything else. `input` should always be a map.

  Useful if you want to do some major changes to the data before further conversion and validation.

  ## Examples

  ```
  # Skip processing if input is already our expected struct
  @impl Constructor
  def before_construct(%__MODULE__{} = input) do
    {:ok, input}
  end

  @impl Constructor
  def before_construct(input) when is_map(input) do
    # Convert the map keys to atoms if they match this modules.
    input = Morphix.atomorphiform!(input, __keys__())

    case input do
      %{name: n, value: v} when is_binary(v) -> {:ok, %__MODULE__{name: n, type: "STRING", value: v}}
      %{name: n, value: v} when is_integer(v) -> {:ok, %__MODULE__{name: n, type: "INTEGER", value: v}}
      _ -> {:ok, input} # you could also return an error tuple here
    end
  end
  ```
  """
  @callback before_construct(input :: map) :: {:ok, struct} | {:error, {:constructor, map}}

  @doc """
  This callback can be used to perform a complex, multi-field validation after all of the per-field
  validations have run.
  """
  @callback after_construct(input :: struct) :: {:ok, struct} | {:error, {:constructor, map}}

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
      # :constructor option is evaluated *after* `:default` or other options.
      field :make, String.t(), default: "", constructor: &is_string/1
      field :model, String.t(), constructor: {Validate, :is_string, []}
      # when a :constructor is defined as a MFA tuple, the field value from input is passed as the
      # 1st argument, with the arguments defined here appended.
      field :vin, String.t(), constructor: [&is_string/1, {CustomValidation, :min_length, [17]}]
    end
  end
  ```

  ## Opts
  *Note:* All opts that `TypedStruct.typedstruct/2` accepts can be passed here as well.

  - `:nil_to_empty` - Whenever `c:new/2` receives a `nil` argument, it will return an empty struct
    with defaults set.  If instead you would like to receive `nil` back, set this option to `false`.
  - `:check_keys` - if `true`, raises KeyError if a key passed is not valid for struct. Raises
  ArgumentError if an enforced key is missing. Note: If `false`, any enforced keys are ignored.
  Defaults to `false`.
  """
  @spec constructor(opts :: keyword) :: Macro.t()
  defmacro constructor(opts \\ [], do: block) do
    opts = Keyword.put(opts, :plugins, [Constructor.TypedStructPlugin])

    quote location: :keep do
      alias Constructor.{Convert, Validate}

      import Kernel,
        except: [is_string: 1, is_atom: 1, is_integer: 1, is_float: 1, is_boolean: 1, is_list: 1]

      import Constructor.Convert
      import Constructor.Validate
      Module.register_attribute(__MODULE__, :constructors, accumulate: true)

      require TypedStruct
      TypedStruct.typedstruct(unquote(opts), do: unquote(block))

      def __constructors__, do: Enum.reverse(@constructors)

      Constructor.__field_constructors__()
      Constructor._default_impl(_opts)
      Constructor._new(unquote(opts))
      defoverridable before_construct: 1, after_construct: 1
      import Kernel
      import Constructor.Convert, only: []
      import Constructor.Validate, only: []
    end
  end

  defmacro _default_impl(_opts) do
    quote do
      @impl Constructor
      def before_construct(struct) do
        {:ok, struct}
      end

      @impl Constructor
      def after_construct(struct) do
        {:ok, struct}
      end

      defp convert_struct(%__MODULE__{} = struct, _, _) do
        {:ok, struct}
      end

      defp convert_struct(%{__struct__: s} = input, opts, check_keys_default) do
        {:ok, Constructor.struct(__MODULE__, opts, check_keys_default, Map.from_struct(input))}
      end

      defp convert_struct(map, opts, check_keys_default) when is_map(map) do
        fields = Morphix.atomorphify!(map, key_strings())
        {:ok, Constructor.struct(__MODULE__, opts, check_keys_default, fields)}
      end

      defp convert_struct(x, _, _), do: {:ok, x}

      def key_strings do
        __keys__() |> Enum.map(&Atom.to_string/1)
      end
    end
  end

  defmacro _new(opts) when is_list(opts) do
    nil_to_empty_global = Keyword.get(opts, :nil_to_empty, true)
    check_keys_global = Keyword.get(opts, :check_keys, false)

    quote do
      @impl Constructor
      def new!(v, opts \\ []) do
        case new(v, opts) do
          {:ok, result} ->
            result

          {:error, _} = e ->
            raise Exception, inspect(e)
        end
      end

      @impl Constructor
      def new(value, opts \\ [])

      @impl Constructor
      def new(nil, opts) do
        nil_to_empty = Keyword.get(opts, :nil_to_empty, unquote(nil_to_empty_global))

        if nil_to_empty do
          new(Constructor.struct(__MODULE__, opts, unquote(check_keys_global)))
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
          new(Enum.into(list, %{}), opts)
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
        with {:ok, before_struct} <- before_construct(map),
             {:ok, struct} <- convert_struct(before_struct, opts, unquote(check_keys_global)),
             {:ok, constructed} <- __field_constructors__(struct),
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

  defmacro __field_constructors__() do
    quote location: :keep do
      @spec __field_constructors__(in_struct :: struct) :: {:ok, struct} | {:error, any}
      def __field_constructors__(in_struct) do
        results =
          Enum.into(__constructors__(), [], fn {field_name, construct_fun} ->
            field = Map.get(in_struct, field_name)
            result = Constructor.__exec_field_fun__(construct_fun, field)

            {field_name, result}
          end)

        case Constructor.__process_result__(results, in_struct) do
          {:ok, struct} = x -> x
          {:error, errors} -> {:error, {:constructor, errors}}
        end
      end
    end
  end

  def __exec_field_fun__(functions, field) when is_list(functions) do
    case Enum.reduce(functions, field, &process_field_funs/2) do
      {:error, _} = e -> e
      result -> {:ok, result}
    end
  end

  def __exec_field_fun__({m, f, a}, field) do
    apply(m, f, [field | a])
  end

  def __exec_field_fun__(fun, field) do
    fun.(field)
  end

  defp process_field_funs(_fun, {:error, _} = e) do
    e
  end

  defp process_field_funs(fun, accumulator) do
    case __exec_field_fun__(fun, accumulator) do
      {:ok, field} -> field
      {:error, _} = e -> e
    end
  end

  def __process_result__(results, struct) do
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

  def struct(m, opts, default, fields \\ []) do
    if Keyword.get(opts, :check_keys, default) == true do
      struct!(m, fields)
    else
      struct(m, fields)
    end
  end
end
