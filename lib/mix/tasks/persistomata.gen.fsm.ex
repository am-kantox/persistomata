defmodule Mix.Tasks.Persistomata.Gen.Fsm do
  @shortdoc "Generates a new FSM implementation with tests and Clickhouse integration"

  @moduledoc @shortdoc <>
               """

               ## Usage

                   mix persistomata.gen.fsm NAME [OPTIONS]

               Where:
                 * NAME — the FSM name in PascalCase (e.g., CoffeeMachine)

               ## Options
                 - **`--fsm-file: :string`** __[optional, default: `nil`]__ the name of the file to read the FSM description from,
                   the `ELIXIR_EDITOR` will be opened to enter a description otherwise
                 - **`--timer: :integer`** __[optional, default: `false`]__ whether to use recurrent calls in
                   this _FSM_ implementation
                 - **`--auto-terminate: :boolean`** __[optional, default: `true`]__ whether the ending states should
                   lead to auto-termination

               ## Examples

                   mix persistomata.gen.fsm --module Turnstile

                   mix persistomata.gen.fsm --module CoffeeMachine --fsm-file priv/fsms/coffee.mermaid
               """
  use Mix.Task

  @default_options [timer: false, auto_terminate: true]

  @impl Mix.Task
  def run(args) do
    case parse_args(args) do
      {:ok, module, options} ->
        fsm_file_option =
          options
          |> Keyword.fetch(:fsm_file)
          |> case do
            {:ok, fsm_file} -> ["--fsm-file", fsm_file]
            _ -> []
          end

        timer_option =
          options
          |> Keyword.fetch(:timer)
          |> case do
            {:ok, timer} when is_integer(timer) -> ["--timer", to_string(timer)]
            _ -> []
          end

        options =
          [
            "--module",
            inspect(module),
            "--generate-test",
            true,
            "--auto-terminate",
            Keyword.fetch!(options, :auto_terminate),
            "--callback",
            "&" <> inspect(__MODULE__) <> ".amend_fsm_file/2"
          ] ++ fsm_file_option ++ timer_option

        Mix.Task.run("finitomata.generate", options)
        generate_migration(module)

      {:error, message} ->
        Mix.raise(message)
    end
  end

  def amend_fsm_file(module, file) do
    with {:ok, content} <- File.read(file),
         true <-
           Mix.shell().yes?("Amend generated #{inspect(module)} with Persistomata goodness?") do
      content =
        content
        |> String.replace(
          "use Finitomata,",
          "use Persistomata\n\nuse Finitomata, persistency: Finitomata.Persistency.Protocol,"
        )
        |> String.replace(
          "defstruct ",
          "@derive JSON.Encoder\ndefstruct "
        )

      File.write(file, Code.format_string!(content))
    end
  end

  defp parse_args(args) do
    {parsed_options, parsed_args, _invalid} =
      OptionParser.parse(args,
        switches: [fsm_file: :string, timer: :integer, auto_terminate: :string]
      )

    case parsed_args do
      [name] ->
        module = Module.concat([name])
        name_not_valid? = module |> inspect() |> String.starts_with?(~s|:"Elixir.|)

        if name_not_valid? do
          {:error, "FSM name must be in PascalCase format (e.g., CoffeeMachine)"}
        else
          options = Keyword.merge(@default_options, parsed_options)
          {:ok, module, options}
        end

      [] ->
        {:error, "Missing NAME. Usage: mix persistomata.gen.fsm NAME [OPTIONS]"}

      _ ->
        {:error, "Too many arguments. Usage: mix persistomata.gen.fsm NAME [OPTIONS]"}
    end
  end

  @default_path "priv/pillar_migrations"

  defp generate_migration(module, path \\ @default_path) do
    dt =
      DateTime.utc_now()
      |> DateTime.truncate(:second)
      |> DateTime.to_iso8601()
      |> String.split("+", trim: true)
      |> hd()
      |> String.replace(~r/\W+/, "-")

    File.mkdir_p!(path)
    table = Macro.underscore(module)
    migration_path = String.replace(table, "\/", "-")

    ~w[table view materialized_view]
    |> Enum.with_index(1)
    |> Enum.each(fn {suffix, idx} ->
      target_file = Path.join(path, "#{dt}_#{idx}_#{suffix}_#{migration_path}.exs")

      Mix.Generator.copy_template(
        Path.expand("pillar_migration_#{suffix}.eex", __DIR__),
        target_file,
        module: module,
        table: Macro.underscore(module)
      )
    end)
  end
end
