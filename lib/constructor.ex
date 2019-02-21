defmodule Constructor do
  @moduledoc """
  Documentation for Constructor.
  """

  defmodule ConstructorException do
    @moduledoc false
    defexception message: "An error occured creating a struct"
  end

  @type new_opts :: [field_name: atom]

  @type conversion :: (field_item :: any -> field_item :: any)

  @type validation :: (String.t() | atom, any -> :ok | {:error, {:constructor, map}})

  @callback new(input :: map | keyword | list(map)) ::
              {:ok, struct | list(struct) | nil} | {:error, {:constructor, map}}

  @callback new(input :: map | keyword | list(map), opts :: new_opts) ::
              {:ok, struct | list(struct) | nil} | {:error, {:constructor, map}}

  @callback new!(input :: map | keyword | list(map) | nil) :: struct | nil | no_return

  @callback new!(input :: map | keyword | list(map | nil), opts :: new_opts) ::
              struct | nil | no_return

  @doc """
  Implement this callback if you have some complex, multi-field conversions that don't make sense in
  the `constructor/2` macro. Or, if you prefer to eschew the `constructor/2` macro entirely.
  """
  @callback before_construct(any) :: {:ok, any} | {:error, {:constructor, map}}

  @doc """
  Implement this callback if you have some complex, multi-field validations that don't make sense in
  the `constructor/2` macro. Or, if you prefer to eschew the `constructor/2` macro entirely. Make a
  best-effort to rescue any errors and convert them to a `{:error, any}` tuple.

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
    _nil_to_empty = Keyword.get(opts, :nil_to_empty, true)

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
      def new(nil, _opts) do
        new(%__MODULE__{})
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

          mapped
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
            result = construct_fun.(field)

            {field_name, result}
          end)

        case Constructor._process_result(results, in_struct) do
          {:ok, struct} = x -> x
          {:error, errors} -> {:error, {:constructor, errors}}
        end
      end
    end
  end

  def _process_result(results, struct) do
    _do_process_result(results, struct, [])
  end

  def _do_process_result([], struct, errors) do
    if Enum.empty?(errors) do
      {:ok, struct}
    else
      {:error, Enum.reverse(errors)}
    end
  end

  def _do_process_result([result | results], struct, errors) do
    case result do
      {field_name, {:error, {:constructor, error}}} ->
        _do_process_result(results, struct, [{field_name, error} | errors])

      {field_name, {:error, error}} ->
        _do_process_result(results, struct, [{field_name, error} | errors])

      {field_name, {:ok, v}} ->
        _do_process_result(results, Map.put(struct, field_name, v), errors)
    end
  end
end
