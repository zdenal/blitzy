defmodule Blitzy.MixProject do
  use Mix.Project

  def project do
    [
      app: :blitzy,
      version: "0.1.0",
      elixir: "~> 1.6",
      escript: [main_module: Blitzy.CLI],
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {Blitzy.Application, []},
      extra_applications: [:logger, :timex, :httpoison]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:httpoison, "~> 1.2"},
      {:timex, "~> 3.3"},
      {:tzdata, "~> 0.1.8", override: true}
    ]
  end
end
