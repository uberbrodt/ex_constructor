defmodule ConstructorTest do
  use ExUnit.Case

  defmodule TestChild do
    use Constructor

    constructor do
      field :id, :string, default: "", constructor: &is_string/1
      field :name, :string, constructor: &is_not_blank/1
      field :age, :integer, constructor: &to_integer/1
    end
  end

  defmodule ConstructorTest do
    use Constructor

    constructor do
      field :id, :string, default: "", constructor: &is_not_blank/1
      field :age, :integer, default: 0, constructor: &to_integer/1
      field :name, :string, constructor: &is_not_blank/1
      field :child, TestChild.t(), constructor: &TestChild.new/1
      field :step_children, [TestChild.t()], default: [], constructor: &TestChild.new/1
    end
  end

  defmodule StepChild do
    @moduledoc false
    use Constructor

    constructor do
      field :id, :string, default: "", constructor: &is_string/1
      field :name, :string, constructor: &is_not_blank/1
    end
  end

  defmodule SimpleChild do
    @moduledoc false
    use Constructor

    constructor do
      field :id, :string, default: "test_id", constructor: &is_string/1
    end
  end

  defmodule SimpleChildConstructorOpts do
    @moduledoc false
    use Constructor

    constructor nil_to_empty: false do
      field :id, :string, default: "test_id", constructor: &is_string/1
    end
  end

  defmodule EnforcedKeyTest do
    @moduledoc false
    use Constructor

    constructor do
      field :id, :string, enforce: true
      field :name, :string, default: "", constructor: &is_string/1
    end
  end

  defmodule CheckKeysGlobalTest do
    @moduledoc false
    use Constructor

    constructor check_keys: true do
      field :id, :string, enforce: true
      field :name, :string, default: "", constructor: &is_string/1
    end
  end

  defmodule TestUser do
    @moduledoc false
    use Constructor

    constructor do
      field :id, :string, default: "", constructor: &is_not_blank/1
      field :first_name, :string, constructor: &is_not_blank/1
      field :last_name, :string, constructor: &is_string/1
    end

    @impl Constructor
    def before_construct(%StepChild{name: name} = s) do
      [first, last] = String.split(name)
      {:ok, %TestUser{id: s.id, first_name: first, last_name: last}}
    end

    @impl Constructor
    def before_construct(struct) do
      super(struct)
    end
  end

  defmodule JamesUser do
    @moduledoc false
    use Constructor

    constructor do
      field :id, :string, default: "", constructor: &is_not_blank/1
      field :first_name, :string, constructor: &is_not_blank/1
      field :last_name, :string, default: "", constructor: &is_string/1
      field :age, integer, default: 0, constructor: &is_integer/1
    end

    def test_kernel_import do
      is_integer(12)
    end

    @impl Constructor
    def after_construct(%{first_name: fname} = v) do
      if fname != "James" do
        {:error, {:constructor, %{first_name: "must be James"}}}
      else
        {:ok, v}
      end
    end

    @impl Constructor
    def before_construct(struct) do
      super(struct)
    end
  end

  defmodule MFAConstructors do
    use Constructor

    constructor do
      field :name, :string, default: "", constructor: {Validate, :is_string, []}
    end
  end

  defmodule NewOptions do
    use Constructor

    constructor do
      field :id, :string, default: "", constructor: &is_not_blank/1
      field :child, SimpleChild.t(), constructor: {SimpleChild, :new, [[nil_to_empty: false]]}
    end
  end

  defmodule ConstructorLists do
    use Constructor

    constructor do
      field :first_name, String.t(),
        constructor: [{Validate, :is_string, []}, {__MODULE__, :string_length, [12]}]

      field :last_name, String.t(),
        default: "Christopher",
        constructor: [&is_string/1, &__MODULE__.string_length/1]
    end

    def string_length(v, size \\ 10) do
      if String.length(v) >= size do
        {:ok, v}
      else
        {:error, "'#{v}' does not meet length of #{size}"}
      end
    end
  end

  defmodule ConstructorLevelOptions do
    use Constructor

    constructor do
      field :id, :string, default: "", constructor: &is_not_blank/1
      field :child, SimpleChildConstructorOpts.t(), constructor: &SimpleChildConstructorOpts.new/1
    end
  end

  describe "new/1" do
    test "when given map that passes validation, returns {:ok, %TestChild{}}" do
      assert TestChild.new(%{name: "Otis"}) == {:ok, %TestChild{name: "Otis", age: 0, id: ""}}
    end

    test "construct fails age validation and returns errors" do
      args = %{age: "7.54", id: "foo", name: "Chris", child: %{name: "Otis"}}

      assert ConstructorTest.new(args) ==
               {:error, {:constructor, %{age: "must be an integer"}}}
    end

    test "turns a list of maps into {:ok, [struct]}" do
      subject = [%{name: "Otis"}, %{name: "Redding"}]
      assert {:ok, result} = TestChild.new(subject)
      assert length(result) == 2
      assert hd(result) == %TestChild{name: "Otis", age: 0, id: ""}
      assert hd(Enum.reverse(result)) == %TestChild{name: "Redding", age: 0, id: ""}
    end

    test "turns a list of maps with an error into {:error, {:constructor, %{idx => errors}}}}" do
      subject = [%{name: "Otis"}, %{name: 12}]
      assert {:error, {:constructor, %{1 => %{name: "must be a string"}}}} = TestChild.new(subject)
    end

    test "nil :child is converted to empty struct" do
      arg = %{name: "Chris", id: "foo", child: default_child()}
      {:ok, %{child: result}} = ConstructorTest.new(arg)
      assert result.__struct__ == TestChild
    end

    test "nil :step_children converted to []" do
      arg = %{name: "Chris", id: "foo", child: default_child()}
      {:ok, %{step_children: result}} = ConstructorTest.new(arg)
      assert result == []
    end

    test "construct fails :name and :id and errors returned for both" do
      arg = %{age: 34, name: "", child: default_child()}

      assert ConstructorTest.new(arg) ==
               {:error, {:constructor, %{id: "must not be blank", name: "must not be blank"}}}
    end

    test "returns error from :child on it's :name constructor" do
      arg = %{name: "Chris", id: "foo", child: %{id: "foo", age: 2}}

      assert ConstructorTest.new(arg) ==
               {:error, {:constructor, %{child: %{name: "must be a string"}}}}
    end

    test "converts StepChild struct to TestChild" do
      {:ok, x} = StepChild.new(name: "Chris")

      assert x == %StepChild{name: "Chris"}

      assert TestChild.new(x) == {:ok, %TestChild{name: "Chris", age: 0}}
    end

    test "{M,F,A} tuples are executed with the field value as arg 0" do
      arg = %{name: "Chris"}
      assert MFAConstructors.new(arg) == {:ok, %MFAConstructors{name: "Chris"}}
    end

    test "nil_to_empty: false option will prevent coercing nil to the struct" do
      args = %{id: "foo", child: nil}
      assert NewOptions.new(args) == {:ok, %NewOptions{id: args[:id], child: nil}}
    end

    test ":nil_to_empty constructor level option" do
      args = %{id: "foo", child: nil}

      assert ConstructorLevelOptions.new(args) ==
               {:ok, %ConstructorLevelOptions{id: args[:id], child: nil}}
    end

    test "executes a list of MFA tuples defined on :constructor" do
      args = %{first_name: "foo"}

      assert ConstructorLists.new(args) ==
               {:error, {:constructor, %{first_name: "'foo' does not meet length of 12"}}}
    end

    test "if function in list returns error tuple, halt running functions and return error" do
      args = %{first_name: 12}

      assert ConstructorLists.new(args) ==
               {:error, {:constructor, %{first_name: "must be a string"}}}
    end

    test "list of function captures for :constructor" do
      args = %{first_name: "Christopoulos", last_name: "Jones"}

      assert ConstructorLists.new(args) ==
               {:error, {:constructor, %{last_name: "'Jones' does not meet length of 10"}}}
    end

    test "passing [check_keys: true] opt will validate @enforce_keys" do
      assert_raise ArgumentError, fn ->
        EnforcedKeyTest.new([name: "Chris"], check_keys: true)
      end
    end

    test "passing [check_keys: true] opt and map argument will validate @enforce_keys" do
      assert_raise ArgumentError, fn ->
        EnforcedKeyTest.new(%{name: "Chris"}, check_keys: true)
      end
    end

    test "passing an invalid key with check_keys will raise KeyError" do
      assert_raise KeyError, fn ->
        EnforcedKeyTest.new(%{id: "foo", middle_name: "Chris"}, check_keys: true)
      end
    end

    test "string keys are converted before @enforce_key is checked" do
      assert {:ok, _} = EnforcedKeyTest.new(%{"id" => "foo", "name" => "Chris"}, check_keys: true)
    end

    test "check_keys global option sets default for new/1" do
      assert_raise ArgumentError, fn ->
        CheckKeysGlobalTest.new(%{name: "Chris"})
      end
    end
  end

  describe "new!/1" do
    test "construct fails age validation and raises ConstructorException" do
      args = %{age: "7.54", id: "foo", name: "Chris", child: %{name: "Otis"}}

      assert_raise(Constructor.Exception, fn -> ConstructorTest.new!(args) end)
    end
  end

  describe "before_construct/1" do
    test "matching function definition is called" do
      {:ok, input} = StepChild.new(name: "John Smith", id: "foo")
      {:ok, x} = TestUser.new(input)
      assert x == %TestUser{first_name: "John", last_name: "Smith", id: input.id}
    end

    test "calling super works" do
      input = %{first_name: "John", last_name: "Hancock", id: "foo"}
      {:ok, x} = TestUser.new(input)
      assert x == %TestUser{first_name: "John", last_name: "Hancock", id: input.id}
    end
  end

  describe "after_construct/1" do
    test "returns error if first_name is not James" do
      args = %{first_name: "Chris", id: "foo"}
      assert JamesUser.new(args) == {:error, {:constructor, %{first_name: "must be James"}}}
    end
  end

  test "Kernel is re-imported after constructor block" do
    assert JamesUser.test_kernel_import() == true
  end

  def default_child do
    %{name: "Otis", age: 11}
  end
end
