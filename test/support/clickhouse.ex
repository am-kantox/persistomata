defmodule Persistomata.Test.Clickhouse do
  @moduledoc false
  alias Rambla.Services.Clickhouse.Conn

  @queries %{
    "persistomata/test/turnstile" => %{
      drop: """
      DROP TABLE "persistomata/test/turnstile"
      """,
      create: """
      CREATE TABLE "persistomata/test/turnstile"
        (
          timestamp DateTime64(9),
          node FixedString(255),
          unique_integer Int64,
          id String,
          name FixedString(36),
          type FixedString(16),
          payload JSON
        )
        ENGINE = MergeTree
        PRIMARY KEY (timestamp, node, unique_integer)
      """,
      select: """
      SELECT * FROM "persistomata/test/turnstile"
      """
    },
    "persistomata/test/coffee_machine" => %{
      drop: """
      DROP TABLE "persistomata/test/coffee_machine"
      """,
      create: """
      CREATE TABLE "persistomata/test/coffee_machine"
        (
          timestamp DateTime64(9),
          node FixedString(255),
          unique_integer Int64,
          id String,
          name FixedString(36),
          type FixedString(16),
          payload JSON
        )
        ENGINE = MergeTree
        PRIMARY KEY (timestamp, node, unique_integer)
      """,
      select: """
      SELECT * FROM "persistomata/test/coffee_machine"
      """
    }
  }

  @turnstile_queries @queries["persistomata/test/turnstile"]
  @coffee_machine_queries @queries["persistomata/test/coffee_machine"]

  def query(query), do: Conn.query(query)

  def drop_table_turnstile, do: query(@turnstile_queries.drop)
  def create_table_turnstile, do: query(@turnstile_queries.create)

  def drop_table_coffee_machine, do: query(@coffee_machine_queries.drop)
  def create_table_coffee_machine, do: query(@coffee_machine_queries.create)

  def prepare do
    drop_table_turnstile()
    drop_table_coffee_machine()
    create_table_turnstile()
    create_table_coffee_machine()
  end

  def select_from_table_turnstile, do: Conn.select(@turnstile_queries.select)
  def select_from_table_coffee_machine, do: Conn.select(@coffee_machine_queries.select)
end
