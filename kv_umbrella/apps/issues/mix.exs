defmodule Issues.MixProject do
  use Mix.Project

  def project do
    [
      app: :issues,
      version: "0.1.0",
      name: "Issues",
      source_url: "https://github.com/SasukeBo/issues",
      extras: ["README.md", "markdown/custom_page.md"],
      elixir: "~> 1.6",
      escript: escript_config(),
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :httpoison, :jsx, :cowboy, :plug],
      # list被传递给Application模块的start函数
      mod: {Issues.Application, [name: :sasuke]}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"},
      {:httpoison, "~> 1.0"},
      {:jsx, "~> 2.0"},
      {:ex_doc, "~> 0.16", only: :dev, runtime: false},
      {:cowboy, "~> 1.0.0"},
      {:plug, "~> 1.0"}
    ]
  end

  defp escript_config do
    [main_module: Issues.CLI]
  end
end
