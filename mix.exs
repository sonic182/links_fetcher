defmodule LinksFetcher.MixProject do
  use Mix.Project

  @description "Sample links fetcher."

  def project do
    [
      app: :links_fetcher,
      version: "0.2.0",
      elixir: "~> 1.8",
      description: @description,
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {LinksFetcher, []}
    ]
  end

  defp package do
    %{
      licenses: ["MIT"],
      maintainers: ["Johanderson Mogollon"],
      links: %{"GitHub" => "https://github.com/sonic182/links_fetcher"},
      files: ["lib", "mix.exs", "README.md", "CHANGELOG.md"]
    }
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:hackney, "~> 1.15"},
      {:ex_doc, ">= 0.0.0", only: :dev}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end
end
