defmodule ConstructorTest do
  use ExUnit.Case

  defmodule TestChild do
    use Constructor

    constructor do
      field :id, :string, default: "", constructor: &Validate.is_string/1
      field :name, :string, constructor: &Validate.is_nonempty_string/1
      field :age, :integer, constructor: &Construct.integer/1
    end
  end

  defmodule ConstructorTest do
    use Constructor

    constructor do
      field :id, :string, default: "", constructor: &Construct.uuid/1
      field :age, :integer, default: 0, constructor: &Construct.integer/1
      field :name, :string, constructor: &Validate.is_nonempty_string/1
      field :child, TestChild.t(), constructor: &TestChild.new/1
      field :step_children, [TestChild.t()], default: [], constructor: &TestChild.new/1
    end
  end

  defmodule StepChild do
    @moduledoc false
    use Constructor

    constructor do
      field :id, :string, default: "", constructor: &Validate.is_string/1
      field :name, :string, constructor: &Validate.is_nonempty_string/1
    end
  end

  defmodule TestUser do
    @moduledoc false
    use Constructor

    constructor do
      field :id, :string, default: "", constructor: &Construct.uuid/1
      field :first_name, :string, constructor: &Validate.is_nonempty_string/1
      field :last_name, :string, constructor: &Validate.is_string/1
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
      field :id, :string, default: "", constructor: &Construct.uuid/1
      field :first_name, :string, constructor: &Validate.is_nonempty_string/1
      field :last_name, :string, default: "", constructor: &Validate.is_string/1
    end

    @impl Constructor
    def after_construct(%{first_name: fname} = v) do
      if fname != "James" do
        {:error, {:constructor, [first_name: "must be James"]}}
      else
        {:ok, v}
      end
    end

    @impl Constructor
    def before_construct(struct) do
      super(struct)
    end
  end

  describe "new/1" do
    test "when given map that passes validation, returns {:ok, %TestChild{}}" do
      assert TestChild.new(%{name: "Otis"}) == {:ok, %TestChild{name: "Otis", age: 0, id: ""}}
    end

    test "construct fails age validation and returns errors" do
      args = %{age: 7.54, id: UUID.uuid4(), name: "Chris", child: %{name: "Otis"}}

      assert ConstructorTest.new(args) ==
               {:error, {:constructor, [age: "must be an integer"]}}
    end

    test "nil :child is converted to empty struct" do
      arg = %{name: "Chris", id: UUID.uuid4(), child: default_child()}
      {:ok, %{child: result}} = ConstructorTest.new(arg)
      assert result.__struct__ == TestChild
    end

    test "nil :step_children converted to []" do
      arg = %{name: "Chris", id: UUID.uuid4(), child: default_child()}
      {:ok, %{step_children: result}} = ConstructorTest.new(arg)
      assert result == []
    end

    test "construct fails :name and :id and errors returned for both" do
      arg = %{age: 34, name: "", child: default_child()}

      assert ConstructorTest.new(arg) ==
               {:error, {:constructor, [id: "must be a UUID", name: "is required"]}}
    end

    test "returns error from :child on it's :name constructor" do
      arg = %{name: "Chris", id: UUID.uuid4(), child: %{id: UUID.uuid4(), age: 2}}

      assert ConstructorTest.new(arg) ==
               {:error, {:constructor, [child: [name: "is required"]]}}
    end

    test "converts StepChild struct to TestChild" do
      {:ok, x} = StepChild.new(name: "Chris")

      assert x == %StepChild{name: "Chris"}

      assert TestChild.new(x) == {:ok, %TestChild{name: "Chris", age: 0}}
    end
  end

  describe "before_construct/1" do
    test "matching function definition is called" do
      {:ok, input} = StepChild.new(name: "John Smith", id: UUID.uuid4())
      {:ok, x} = TestUser.new(input)
      assert x == %TestUser{first_name: "John", last_name: "Smith", id: input.id}
    end

    test "calling super works" do
      input = %{first_name: "John", last_name: "Hancock", id: UUID.uuid4()}
      {:ok, x} = TestUser.new(input)
      assert x == %TestUser{first_name: "John", last_name: "Hancock", id: input.id}
    end
  end

  describe "after_construct/1" do
    test "returns error if first_name is not James" do
      args = %{first_name: "Chris", id: UUID.uuid4()}
      assert JamesUser.new(args) == {:error, {:constructor, [first_name: "must be James"]}}
    end

  end

  def default_child do
    %{name: "Otis", age: 11}
  end
end
