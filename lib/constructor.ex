defmodule Constructor do
  @moduledoc ~S"""
  Constructor is a library that reduces boilerplate when defining stucts by enabling per-field
  validations and generating methods that are used to "construct" a struct.

  A simple example is the following:


  ```
  defmodule DocTestUser do
    use Constructor

    constructor do
      field :id, :integer, construct: &Validate.is_integer/1
      field :first_name, :string, default: "", construct: &Validate.is_string/1
      field :last_name, :string, default: "", construct: &Validate.is_string/1
    end
  end

  DocTestUser.new(id: "foo", first_name: 37)
  {:error, {:constructor, [id: "must be an integer", first_name: "must be an integer"]}}

  iex> DocTestUser.new(id: 12, first_name: "Chris")
  {:ok, %DocTestUser{id: 12, first_name: "Chris", last_name: ""}}

  iex> DocTestUser.new!(id: 12, first_name: "Chris")
  %DocTestUser{id: 12, first_name: "Chris", last_name: ""}
  ```

  A few things to note here:
    * `new/1` and `new!/1` functions are generated, and accept a map, keyword list or a list of maps
    * The `:construct` functions are run for each field, and any errors are returned in a keyword
      list
    * `default` values are applied *before* the `:construct` functions
    * `Constructor.Validate` and `Constructor.Convert` are automatically aliased
    * the `:construct` attribute accepts either a function capture (as above), a {M,F,A} tuple, or a
    list of function captures or MFA tuples.


  Any function that conforms to `t:constructor_fun/1` can be used in the `construct` field.
  Additionally, a `new/1` function can also be used to build out a nested struct. For example:

  ```
  defmodule DocTestAdmin do
    use Constructor

    constructor do
      field :id, :integer, construct: &Validate.is_integer/1
      field :user, DocTestUser.t(), construct: &DocTestUser.new/1
    end
  end

  iex> DocTestAdmin.new!(id: 22, user: %{id: 22, first_name: "Chris"})
  %DocTestAdmin{id: 22, user: %DocTestUser{id: 22, first_name: "Chris"}}
  ```


  ## Acknowledgements
  This library was born from the lack of a lightweight (but powerful!) validation library in Elixir
  that doesn't depend on Ecto. The `constructor` macro comes almost entirely from the excellent
  `typed_struct` library, save for a plugin mechanism.
  """

  defmodule ConstructorException do
    @moduledoc false
    defexception message: "An error occured creating a struct"
  end

  @type new_opts :: [nil_to_empty: boolean]

  @type constructor_fun :: (field_item :: any -> field_item :: any | {:error, String.t()})

  @callback new(input :: map | keyword | list(map)) ::
              {:ok, struct | list(struct) | nil} | {:error, {:constructor, map}}

  @doc """
  Build this struct from a map, struct or keyword list. Also accepts a list of maps that will be
  iterated to convert each to the new function.

  ### Opts
  - `nil_to_empty`: if `true`, convert a nil `input` into an empty struct. Defaults to `true`
  """
  @callback new(input :: map | keyword | list(map), opts :: new_opts) ::
              {:ok, struct | list(struct) | nil} | {:error, {:constructor, map}}

  @callback new!(input :: map | keyword | list(map) | nil) :: struct | nil | no_return

  @doc """
  Same as `new/2`, but returns the untagged struct or raises a ConstructorException
  """
  @callback new!(input :: map | keyword | list(map | nil), opts :: new_opts) ::
              struct | nil | no_return

  @doc """
  The callback can be used to modify an input to `new/2` before the constructor functions are
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
      alias Constructor.{Construct, Convert, Validate}
    end
  end

  @doc """
  Declare a struct and it's fields. Set's the default options for the struct.

  ### Opts
  - `nil_to_empty`: if `true`, convert a nil `input` into an empty struct. Defaults to `true`
  """
  @spec constructor(opts :: keyword) :: Macro.t()
  defmacro constructor(opts \\ [], do: block) do
    opts = Keyword.put(opts, :plugins, [Constructor.TypedStructPlugin])

    quote location: :keep do
      Module.register_attribute(__MODULE__, :constructors, accumulate: true)

      require TypedStruct
      TypedStruct.typedstruct(unquote(opts), do: unquote(block))

      def __constructors__, do: Enum.reverse(@constructors)

      Constructor._field_constructors()
      Constructor._default_impl(_opts)
      Constructor._new(unquote(opts))
      defoverridable before_construct: 1, after_construct: 1
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
      {:error, Enum.reverse(errors)}
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
