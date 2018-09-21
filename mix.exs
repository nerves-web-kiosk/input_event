defmodule InputEvent.Mixfile do
  use Mix.Project

  @app :input_event

  def project do
    [
      app: @app,
      version: "0.3.0",
      elixir: "~> 1.3",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      make_clean: ["clean"],
      make_env: make_env(),
      compilers: [:elixir_make | Mix.compilers()],
      deps: deps(),
      docs: [extras: ["README.md"], main: "readme"]
    ]
  end

  def application do
    [applications: []]
  end

  defp deps do
    [
      {:elixir_make, "~> 0.4", runtime: false},
      {:ex_doc, "~> 0.18", only: [:dev, :test], runtime: false}
    ]
  end

  defp description do
    "Elixir interface to Linux input event devices"
  end

  defp package do
    [
      maintainers: ["Justin Schneck"],
      licenses: ["Apache 2.0"],
      links: %{"Github" => "https://github.com/letoteteam/#{@app}"}
    ]
  end

  defp make_env() do
    case System.get_env("ERL_EI_INCLUDE_DIR") do
      nil ->
        %{
          "ERL_EI_INCLUDE_DIR" => "#{:code.root_dir()}/usr/include",
          "ERL_EI_LIBDIR" => "#{:code.root_dir()}/usr/lib"
        }

      _ ->
        %{}
    end
  end
end
