defmodule Persistomata.Test.CoffeeMachine.Test do
  use ExUnit.Case
  import Finitomata.ExUnit
  import Mox

  @moduletag :finitomata

  describe "↝‹:* ↦ :idle ↦ :ready ↦ :brewing ↦ :done ↦ :ready ↦ :off ↦ :*›" do
    setup_finitomata do
      parent = self()

      [
        fsm: [
          implementation: Persistomata.Test.CoffeeMachine,
          payload: 0,
          options: [transition_count: 7]
        ],
        context: [parent: parent]
      ]
    end

    test_path "path #0", %{finitomata: %{}, parent: _} = _ctx do
      :* ->
        # these validations allow `assert_payload/2` calls only
        #
        # also one might pattern match to entry events with payloads directly
        # %{finitomata: %{auto_init_msgs: [idle: :foo, started: :bar]} = _ctx
        assert_state(:idle)

        assert_state :ready do
          # assert_payload %{}
        end

      :insert_money ->
        assert_state :brewing do
          # assert_payload %{foo: :bar}
        end

      :finish ->
        assert_state :done do
          # assert_payload %{foo: :bar}
        end

      {:take_coffee, nil} ->
        assert_state :ready do
          # assert_payload %{foo: :bar}
        end

      {:power_off, nil} ->
        assert_state :off do
          # assert_payload %{foo: :bar}
        end

        assert_state :* do
          assert_payload do
            # foo.bar.baz ~> ^parent
          end
        end
    end
  end

  describe "↝‹:* ↦ :idle ↦ :ready ↦ :brewing ↦ :done ↦ :off ↦ :*›" do
    setup_finitomata do
      parent = self()

      [
        fsm: [
          implementation: Persistomata.Test.CoffeeMachine,
          payload: 0,
          options: [transition_count: 6]
        ],
        context: [parent: parent]
      ]
    end

    test_path "path #1", %{finitomata: %{}, parent: _} = _ctx do
      :* ->
        # these validations allow `assert_payload/2` calls only
        #
        # also one might pattern match to entry events with payloads directly
        # %{finitomata: %{auto_init_msgs: [idle: :foo, started: :bar]} = _ctx
        assert_state(:idle)

        assert_state :ready do
          # assert_payload %{}
        end

      {:insert_money, nil} ->
        assert_state :brewing do
          # assert_payload %{foo: :bar}
        end

      {:finish, nil} ->
        assert_state :done do
          # assert_payload %{foo: :bar}
        end

      {:power_off, nil} ->
        assert_state :off do
          # assert_payload %{foo: :bar}
        end

        assert_state :* do
          assert_payload do
            # foo.bar.baz ~> ^parent
          end
        end
    end
  end

  describe "↝‹:* ↦ :idle ↦ :ready ↦ :off ↦ :*›" do
    setup_finitomata do
      parent = self()

      [
        fsm: [
          implementation: Persistomata.Test.CoffeeMachine,
          payload: 0,
          options: [transition_count: 4]
        ],
        context: [parent: parent]
      ]
    end

    test_path "path #2", %{finitomata: %{}, parent: _} = _ctx do
      :* ->
        # these validations allow `assert_payload/2` calls only
        #
        # also one might pattern match to entry events with payloads directly
        # %{finitomata: %{auto_init_msgs: [idle: :foo, started: :bar]} = _ctx
        assert_state(:idle)

        assert_state :ready do
          # assert_payload %{}
        end

      {:power_off, nil} ->
        assert_state :off do
          # assert_payload %{foo: :bar}
        end

        assert_state :* do
          assert_payload do
            # foo.bar.baz ~> ^parent
          end
        end
    end
  end
end
