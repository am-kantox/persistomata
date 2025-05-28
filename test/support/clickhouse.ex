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
          monotonic Int64,
          unique_integer Int64,
          id String,
          name String,
          node String,
          timestamp DateTime64(9),
          type String,
          payload JSON
        )
        ENGINE = MergeTree
        PRIMARY KEY (monotonic, unique_integer)
      """,
      select: """
      SELECT * FROM "persistomata/test/turnstile"
      """
    }
  }

  @turnstile_queries @queries["persistomata/test/turnstile"]

  def query(query), do: Conn.query(query)

  def drop_table_turnstile, do: query(@turnstile_queries.drop)
  def create_table_turnstile, do: query(@turnstile_queries.create)

  def prepare do
    drop_table_turnstile()
    create_table_turnstile()
  end

  def select_from_table_turnstile, do: Conn.select(@turnstile_queries.select)
end
