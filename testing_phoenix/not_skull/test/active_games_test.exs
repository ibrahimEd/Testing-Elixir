defmodule NotSkull.ActiveGamesTest do
  use ExUnit.Case
  alias NotSkull.ActiveGames
  alias Support.Factory
  alias NotSkull.GameEngine
  alias NotSkull.Errors.GameError
  import Support.AssertionHelpers
  import Mox

  setup [:set_mox_global, :verify_on_exit!]

  describe "new_game/0" do
    test "success: it returns a new game" do
      assert {:ok, %GameEngine.Game{id: new_game_id} = new_game} =
               ActiveGames.new_game()

      assert is_uuid(new_game_id)

      expected_game = %GameEngine.Game{
        current_card: nil,
        current_logging: [],
        current_phase: :joining,
        current_player_id: nil,
        id: new_game_id,
        logs: [],
        players: []
      }

      assert new_game == expected_game
    end

    test "success: it accepts overrides" do
      players = [Factory.struct_for(:player)]

      assert {:ok, %GameEngine.Game{id: new_game_id} = new_game} =
               ActiveGames.new_game(players: players)

      assert is_uuid(new_game_id)

      assert %GameEngine.Game{
               active?: false,
               current_card: nil,
               current_logging: current_logging,
               current_phase: :joining,
               current_player_id: nil,
               id: ^new_game_id,
               logs: [],
               players: ^players
             } = new_game

      refute Enum.empty?(current_logging)
    end
  end

  describe "start/2" do
    test "success: it starts a game" do
      players = [
        Factory.struct_for(:player),
        Factory.struct_for(:player)
      ]

      {:ok, new_game} = ActiveGames.new_game(players: players)

      assert {:ok, %GameEngine.Game{} = returned_game} =
               ActiveGames.start(new_game.id, Enum.random(players))

      assert_values_for(
        expected: new_game,
        actual: returned_game,
        fields:
          fields_for(%GameEngine.Game{}) --
            [
              :active?,
              :current_logging,
              :current_phase,
              :current_player_id,
              :logs,
              :players
            ]
      )

      assert returned_game.current_phase == :choose_card
      assert returned_game.active? == true

      expected_player_ids = for player <- new_game.players, do: player.id

      assert returned_game.current_player_id in expected_player_ids

      assert_unordered_lists_are_equal(
        expected: players,
        actual: returned_game.players
      )
    end

    test "error: it returns an error tuple if game can't be started, does not update state" do
      players = [Factory.struct_for(:player), Factory.struct_for(:player)]
      {:ok, new_game} = ActiveGames.new_game(players: players)

      {:ok, %GameEngine.Game{}} =
        ActiveGames.start(new_game.id, Enum.random(players))

      before_state = gen_server_state()

      assert {:error, %GameError{}} =
               ActiveGames.start(new_game.id, Enum.random(players))

      assert gen_server_state() == before_state
    end
  end

  describe "join/2" do
    setup do
      {:ok, new_game} = ActiveGames.new_game()
      %{new_game: new_game}
    end

    test "success: it adds player to game, returns game", %{
      new_game: new_game
    } do
      player = Factory.struct_for(:player)

      assert {:ok, updated_game} = ActiveGames.join(new_game.id, player)

      expected_game = %{new_game | players: new_game.players ++ [player]}

      assert_values_for(
        expected: expected_game,
        actual: updated_game,
        fields: fields_for(new_game) -- [:current_logging]
      )

      assert "#{player.name} has joined the game." in updated_game.current_logging
    end

    test "error: it returns an error if player can't join" do
      players = for _x <- 1..3, do: Factory.struct_for(:player)
      {:ok, new_game} = ActiveGames.new_game(players: players)

      {:ok, started_game} =
        ActiveGames.start(new_game.id, Enum.random(players))

      assert {:error, %GameError{}} =
               ActiveGames.join(started_game.id, Factory.struct_for(:player))
    end
  end

  describe "move/2" do
    setup do
      players = for _x <- 2..12, do: Factory.struct_for(:player)
      {:ok, new_game} = ActiveGames.new_game(players: players)

      %{new_game: new_game}
    end

    test "success: it calls the game engine with the correct game and move",
         %{new_game: new_game} do
      player = Enum.random(new_game.players)
      expected_move = Factory.struct_for(:move, %{player_id: player.id})

      # changing something so that we can make sure ActiveGames returns what it gets from the dependency.
      expected_returned_game = %{new_game | current_phase: :game_summary}

      expect(GameEngineMock, :update_game, fn game, move ->
        assert game == new_game
        assert move == expected_move
        {:ok, expected_returned_game}
      end)

      assert {:ok, returned_game} =
               ActiveGames.move(new_game.id, expected_move)

      assert returned_game == expected_returned_game

      assert Map.get(gen_server_state(), new_game.id) ==
               expected_returned_game
    end

    test "error: returns error tuple if move can't be made", %{
      new_game: new_game
    } do
      expected_error =
        GameError.exception(message: "I'm a game error message.")

      stub(GameEngineMock, :update_game, fn _game, _move ->
        {:error, expected_error}
      end)

      assert {:error, %GameError{}} =
               ActiveGames.move(new_game.id, Factory.struct_for(:move))

      assert Map.get(gen_server_state(), new_game.id) == new_game
    end
  end

  describe "get_game_by_id/1" do
    test "success: it returns a new game if it doesn't already exist" do
      {:ok, %GameEngine.Game{} = new_game} = ActiveGames.new_game()

      assert {:ok, %GameEngine.Game{} = returned_game} =
               ActiveGames.get_game_by_id(new_game.id)

      assert returned_game == new_game
    end

    test "error: it returns an error tuple if game doesn't exist" do
      assert {:error, %GameError{message: message}} =
               ActiveGames.get_game_by_id(Factory.uuid())

      assert message = "That game doesn't exist or is no longer active."
    end
  end

  describe "all/0" do
    test "success: returns all active game IDs" do
      {:ok, %GameEngine.Game{} = new_game} = ActiveGames.new_game()

      all_game_ids = ActiveGames.all()
      assert is_list(all_game_ids)
      assert new_game.id in all_game_ids
    end
  end

  defp gen_server_state do
    :sys.get_state(ActiveGames)
  end
end
