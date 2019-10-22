defmodule Constructor.MixProject do
  use Mix.Project

  def project do
    [
      app: :constructor,
      version: "1.1.0",
      description: description(),
      docs: [main: Constructor],
      elixir: "~> 1.7",
      elixirc_paths: elixirc_paths(Mix.env()),
      package: package(),
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp package do
    [
      # files: ["lib", "mix.exs", "README.md", "LICENSE"],
      maintainers: ["Chris Brodt"],
      licenses: ["LGPL-V3"],
      source_url: "https://github.com/uberbrodt/ex_constructor",
      links: %{"Github" => "https://github.com/uberbrodt/ex_constructor"}
    ]
  end

  defp description do
    "A library for declaratively defining structs with field-level coercions and validations"
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, "~> 0.19", only: :dev, runtime: false},
      {:dialyxir, "~> 1.0.0-rc.6", only: [:dev, :test], runtime: false},
      {:morphix, "~> 0.6"},
      {:typed_struct, "~> 0.1.4", hex: :typed_struct_uberbrodt}
    ]
  end
end
