defmodule Persistomata.Test.Turnstile.Test do
  use ExUnit.Case
  import Finitomata.ExUnit
  import Mox

  @moduletag :finitomata

  describe "↝‹:* ↦ :idle ↦ :closed ↦ :opened ↦ :opened ↦ :opened ↦ :closed ↦ :inactive ↦ :*›" do
    setup_finitomata do
      parent = self()

      [
        fsm: [
          implementation: Persistomata.Test.Turnstile,
          payload: 0,
          options: [transition_count: 8]
        ],
        context: [parent: parent]
      ]
    end

    test_path "path #0", %{finitomata: %{}, parent: _} = _ctx do
      :* ->
        assert_state(:idle)

        assert_state :closed do
          assert_payload(0)
        end

      {:coin, 1} ->
        assert_state :opened do
          assert_payload(1)
        end

      {:coin, 1} ->
        assert_state :opened do
          assert_payload(2)
        end

      {:walk, 1} ->
        assert_state :opened do
          assert_payload(1)
        end

      {:walk, 1} ->
        assert_state :closed do
          assert_payload(0)
        end

      {:off, nil} ->
        assert_state(:inactive)
        assert_state(:*)
    end
  end

  describe "↝‹:* ↦ :idle ↦ :closed ↦ :opened ↦ :opened ↦ :closed ↦ :inactive ↦ :*›" do
    setup_finitomata do
      parent = self()

      [
        fsm: [
          implementation: Persistomata.Test.Turnstile,
          payload: 0,
          options: [transition_count: 7]
        ],
        context: [parent: parent]
      ]
    end

    test_path "path #1", %{finitomata: %{}, parent: _} = _ctx do
      :* ->
        assert_state(:idle)
        assert_state(:closed)

      {:coin, 1} ->
        assert_state :opened do
          assert_payload(1)
        end

      {:coin, 1} ->
        assert_state :opened do
          assert_payload(2)
        end

      {:walk, 2} ->
        assert_state :closed do
          assert_payload(0)
        end

      :off ->
        assert_state(:inactive)
        assert_state(:*)
    end
  end

  describe "↝‹:* ↦ :idle ↦ :closed ↦ :opened ↦ :closed ↦ :opened ↦ :closed ↦ :inactive ↦ :*›" do
    setup_finitomata do
      parent = self()

      [
        fsm: [
          implementation: Persistomata.Test.Turnstile,
          payload: 0,
          options: [transition_count: 8]
        ],
        context: [parent: parent]
      ]
    end

    test_path "path #2", %{finitomata: %{}, parent: _} = _ctx do
      :* ->
        assert_state(:idle)
        assert_state(:closed)

      {:coin, 1} ->
        assert_state :opened do
          assert_payload(1)
        end

      {:walk, 1} ->
        assert_state :closed do
          assert_payload(0)
        end

      {:coin, 1} ->
        assert_state :opened do
          assert_payload(1)
        end

      {:walk, 1} ->
        assert_state :closed do
          assert_payload(0)
        end

      {:off, nil} ->
        assert_state(:inactive)
        assert_state(:*)
    end
  end

  describe "↝‹:* ↦ :idle ↦ :closed ↦ :opened ↦ :closed ↦ :inactive ↦ :*›" do
    setup_finitomata do
      parent = self()

      [
        fsm: [
          implementation: Persistomata.Test.Turnstile,
          payload: 0,
          options: [transition_count: 6]
        ],
        context: [parent: parent]
      ]
    end

    test_path "path #4", %{finitomata: %{}, parent: _} = _ctx do
      :* ->
        assert_state(:idle)

        assert_state :closed do
          # assert_payload %{}
        end

      {:coin, 1} ->
        assert_state :opened do
          assert_payload(1)
        end

      {:walk, 1} ->
        assert_state :closed do
          assert_payload(0)
        end

      {:off, nil} ->
        assert_state(:inactive)
        assert_state(:*)
    end
  end

  describe "↝‹:* ↦ :idle ↦ :closed ↦ :inactive ↦ :*›" do
    setup_finitomata do
      parent = self()

      [
        fsm: [
          implementation: Persistomata.Test.Turnstile,
          payload: 0,
          options: [transition_count: 4]
        ],
        context: [parent: parent]
      ]
    end

    test_path "path #5", %{finitomata: %{}, parent: _} = _ctx do
      :* ->
        assert_state(:idle)
        assert_state(:closed)

      {:off, nil} ->
        assert_state :inactive do
          assert_payload(0)
        end

        assert_state :* do
          assert_payload(0)
        end
    end
  end
end
