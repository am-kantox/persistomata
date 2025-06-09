defmodule Persistomata.Test.Clickhouse do
  @moduledoc false
  alias Rambla.Services.Clickhouse.Conn

  @queries %{
    "persistomata/test/turnstile" => %{
      drop: """
      DROP TABLE "persistomata/test/turnstile"
      """,
      drop_latest: """
      DROP TABLE "persistomata/test/turnstile/__latest__"
      """,
      drop_view: """
      DROP TABLE "persistomata/test/turnstile/__latest__/__view__"
      """,
      create: """
      CREATE TABLE "persistomata/test/turnstile"
        (
          created_at DateTime64(9),
          node FixedString(255),
          unique_integer Int64,
          id String,
          name FixedString(36),
          type FixedString(16),
          payload JSON
        )
        ENGINE = MergeTree
        PRIMARY KEY (created_at, node, unique_integer)
      """,
      create_latest: """
      CREATE TABLE "persistomata/test/turnstile/__latest__"
        (
          id String,
          name FixedString(36),
          updated_at DateTime64(9),
          payload JSON
        )
        ENGINE = ReplacingMergeTree(updated_at)
        ORDER BY (id, name)
        PRIMARY KEY (id, name)
      """,
      create_view: """
      CREATE MATERIALIZED VIEW "persistomata/test/turnstile/__latest__/__view__" TO "persistomata/test/turnstile/__latest__" AS
        SELECT
          id,
          name,
          max(created_at) AS updated_at,
          argMax(payload, created_at) as payload
        FROM "persistomata/test/turnstile"
        WHERE type = 'state'
        GROUP BY (id, name)
        ORDER BY updated_at DESC
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

  def drop_table_turnstile do
    {:drop_turnstile,
     [
       query(@turnstile_queries.drop_view),
       query(@turnstile_queries.drop_latest),
       query(@turnstile_queries.drop)
     ]}
  end

  def create_table_turnstile do
    {:create_turnstile,
     [
       query(@turnstile_queries.create),
       query(@turnstile_queries.create_latest),
       query(@turnstile_queries.create_view)
     ]}
  end

  def drop_table_coffee_machine, do: query(@coffee_machine_queries.drop)
  def create_table_coffee_machine, do: query(@coffee_machine_queries.create)

  def prepare do
    {:prepare,
     [
       drop_table_turnstile(),
       drop_table_coffee_machine(),
       create_table_turnstile(),
       create_table_coffee_machine()
     ]}
  end

  def select_from_table_turnstile, do: Conn.select(@turnstile_queries.select)
  def select_from_table_coffee_machine, do: Conn.select(@coffee_machine_queries.select)
end
