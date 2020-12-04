defmodule InputEvent.MixProject do
  use Mix.Project

  @app :input_event

  def project do
    [
      app: @app,
      version: "0.4.0",
      elixir: "~> 1.4",
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      make_clean: ["clean"],
      compilers: [:elixir_make | Mix.compilers()],
      make_targets: ["all"],
      make_clean: ["clean"],
      deps: deps(),
      docs: [extras: ["README.md"], main: "readme"],
      aliases: [format: [&format_c/1, "format"]]
    ]
  end

  def application do
    []
  end

  defp deps do
    [
      {:elixir_make, "~> 0.6", runtime: false},
      {:ex_doc, "~> 0.23", only: [:docs], runtime: false}
    ]
  end

  defp description do
    "Elixir interface to Linux input event devices"
  end

  defp package do
    [
      files: [
        "lib",
        "src/*.[ch]",
        "test",
        "mix.exs",
        "README.md",
        "LICENSE",
        "CHANGELOG.md",
        "Makefile"
      ],
      licenses: ["Apache-2.0"],
      links: %{"GitHub" => "https://github.com/nerves-web-kiosk/#{@app}"}
    ]
  end

  defp format_c([]) do
    astyle =
      System.find_executable("astyle") ||
        Mix.raise("""
        Could not format C code since astyle is not available.
        """)

    System.cmd(astyle, ["-n", "-r", "src/*.c", "src/*.h"], into: IO.stream(:stdio, :line))
  end

  defp format_c(_args), do: true
end
