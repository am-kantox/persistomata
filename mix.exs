defmodule Persistomata.MixProject do
  use Mix.Project

  @app :persistomata
  @version "0.1.0"

  def project do
    [
      app: @app,
      version: @version,
      elixir: "~> 1.12",
      compilers: compilers(Mix.env()),
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      consolidate_protocols: Mix.env() not in [:dev],
      prune_code_paths: Mix.env() not in [:test, :dev],
      description: description(),
      package: package(),
      deps: deps(),
      aliases: aliases(),
      docs: docs(),
      test_coverage: [tool: ExCoveralls],
      releases: [],
      dialyzer: [
        plt_file: {:no_warn, ".dialyzer/dialyzer.plt"},
        plt_add_deps: :app_tree,
        plt_add_apps: [:mix],
        list_unused_filters: true,
        ignore_warnings: ".dialyzer/ignore.exs"
      ]
    ]
  end

  def application do
    [
      extra_applications: [],
      mod: {Persistomata.Application, []},
      start_phases: [{:persistomata_setup, []}],
      registered: [Persistomata, Persistomata.Application]
    ]
  end

  def cli do
    [preferred_envs: ["coveralls.json": :test, "coveralls.html": :test]]
  end

  defp deps do
    [
      {:pillar, "~> 0.39"},
      {:finitomata, "~> 0.33"},
      {:telemetria, "~> 0.22"},
      {:rambla, "~> 1.4"},
      {:antenna, "~> 0.4"},
      # dev / test
      {:mox, "~> 1.0", only: [:dev, :test]},
      {:doctest_formatter, "~> 0.2", runtime: false},
      {:enfiladex, "~> 0.3", only: [:dev, :test]},
      {:excoveralls, "~> 0.14", only: [:test], runtime: false},
      {:credo, "~> 1.0", only: [:dev, :test]},
      {:dialyxir, "~> 1.0", only: [:dev, :test], runtime: false},
      # {:mneme, "~> 0.6", only: [:dev, :test]},
      {:ex_doc, ">= 0.0.0", only: [:dev]}
    ]
  end

  defp aliases do
    [
      test: ["test --exclude enfiladex"],
      quality: ["format", "credo --strict", "dialyzer"],
      "quality.ci": [
        "format --check-formatted",
        "credo --strict",
        "dialyzer"
      ]
    ]
  end

  defp description do
    """
    The event log framework, ready to use with Redis, Clickhouse, RabbitMQ, and PostgreSQL
    """
  end

  defp package do
    [
      name: @app,
      files: ~w|lib stuff .formatter.exs .dialyzer/ignore.exs mix.exs README* LICENSE|,
      maintainers: ["Aleksei Matiushkin"],
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/am-kantox/#{@app}",
        "Docs" => "https://hexdocs.pm/#{@app}"
      }
    ]
  end

  defp docs do
    [
      main: "architecture",
      source_ref: "v#{@version}",
      canonical: "http://hexdocs.pm/#{@app}",
      logo: "stuff/#{@app}-48x48.png",
      source_url: "https://github.com/am-kantox/#{@app}",
      extras: ~w[README.md stuff/architecture.md],
      groups_for_modules: [],
      groups_for_docs: [
        "Functions (Client)": &(&1[:section] == :client),
        "Functions (Setup)": &(&1[:section] == :setup),
        "Functions (Internals)": &(&1[:section] == :internals)
      ],
      before_closing_body_tag: &before_closing_body_tag/1
    ]
  end

  defp elixirc_paths(:dev), do: ["lib", "test/support"]
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp compilers(_), do: [:finitomata, :telemetria | Mix.compilers()]

  defp before_closing_body_tag(:html) do
    """
    <script defer src="https://cdn.jsdelivr.net/npm/mermaid@10.2.3/dist/mermaid.min.js"></script>
    <script>
      let initialized = false;

      window.addEventListener("exdoc:loaded", () => {
        if (!initialized) {
          mermaid.initialize({
            startOnLoad: false,
            theme: document.body.className.includes("dark") ? "dark" : "default"
          });
          initialized = true;
        }

        let id = 0;
        for (const codeEl of document.querySelectorAll("pre code.mermaid")) {
          const preEl = codeEl.parentElement;
          const graphDefinition = codeEl.textContent;
          const graphEl = document.createElement("div");
          const graphId = "mermaid-graph-" + id++;
          mermaid.render(graphId, graphDefinition).then(({svg, bindFunctions}) => {
            graphEl.innerHTML = svg;
            bindFunctions?.(graphEl);
            preEl.insertAdjacentElement("afterend", graphEl);
            preEl.remove();
          });
        }
      });
    </script>
    """
  end

  defp before_closing_body_tag(_), do: ""
end
