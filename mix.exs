defmodule ReqChronicle.MixProject do
  use Mix.Project

  def project do
    [
      app: :req_chronicle,
      version: "0.1.0",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:bypass, "~> 2.1", only: :test},
      {:ecto_sql, "~> 3.10"},
      {:nimble_options, "~> 1.1"},
      {:req, "~> 0.5.0"},
      {:styler, "~> 1.0.0-rc.0", only: [:dev, :test], runtime: false}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end
end
