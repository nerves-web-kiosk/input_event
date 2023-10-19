defmodule InputEvent.MixProject do
  use Mix.Project

  @version "1.4.2"
  @source_url "https://github.com/nerves-web-kiosk/input_event"

  def project do
    [
      app: :input_event,
      version: @version,
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      make_clean: ["clean"],
      compilers: [:elixir_make | Mix.compilers()],
      make_targets: ["all"],
      make_clean: ["clean"],
      deps: deps(),
      docs: docs(),
      aliases: [format: [&format_c/1, "format"]],
      dialyzer: [
        flags: [:missing_return, :extra_return, :unmatched_returns, :error_handling, :underspecs]
      ],
      preferred_cli_env: %{
        docs: :docs,
        "hex.publish": :docs,
        "hex.build": :docs
      }
    ]
  end

  def application do
    [extra_applications: [:logger]]
  end

  defp deps do
    [
      {:credo, "~> 1.6", only: :dev, runtime: false},
      {:credo_binary_patterns, "~> 0.2", only: :dev, runtime: false},
      {:elixir_make, "~> 0.6", runtime: false},
      {:ex_doc, "~> 0.23", only: [:docs], runtime: false},
      {:dialyxir, "~> 1.2", only: :dev, runtime: false}
    ]
  end

  defp description do
    "Elixir interface to Linux input event devices"
  end

  defp docs do
    [
      extras: ["README.md"],
      main: "readme",
      source_ref: "v#{@version}",
      source_url: @source_url
    ]
  end

  defp package do
    [
      files: [
        "lib",
        "c_src/*.[ch]",
        "mix.exs",
        "README.md",
        "LICENSE",
        "CHANGELOG.md",
        "Makefile"
      ],
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => @source_url}
    ]
  end

  defp format_c([]) do
    astyle =
      System.find_executable("astyle") ||
        Mix.raise("""
        Could not format C code since astyle is not available.
        """)

    options = [
      "-n",
      "-r",
      "--style=kr",
      "--indent=spaces=4",
      "--align-pointer=name",
      "--align-reference=name",
      "--convert-tabs",
      "--attach-namespaces",
      "--max-code-length=100",
      "--max-continuation-indent=120",
      "--pad-header",
      "--pad-oper",
      "c_src/*.c"
    ]

    System.cmd(astyle, options, into: IO.stream(:stdio, :line))
  end

  defp format_c(_args), do: true
end
