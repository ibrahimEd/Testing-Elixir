# START:file_and_setup
defmodule NotSkullWeb.LobbyChannelTest do
  use NotSkullWeb.ChannelCase
  alias NotSkullWeb.{LobbyChannel, UserSocket}

  describe "broadcast_new_game/1" do
    setup do
      user_id = Factory.uuid() # <label id="code.testing_phoenix.channels.lobby_channel_test.user_uuid"/>

      {:ok, _, socket} =
        UserSocket
        |> socket("user_socket:#{user_id}", %{user_id: user_id}) # <label id="code.testing_phoenix.channels.lobby_channel_test.socket"/>
        |> subscribe_and_join(LobbyChannel, "lobby:lobby") # <label id="code.testing_phoenix.channels.lobby_channel_test.subscribe_and_join"/>

      %{socket: socket}
    end
    # END:file_and_setup

    # START:happy_path
    test "success: returns :ok, sends broadcast when passed an open game" do  # <label id="code.testing_phoenix.channels.lobby_channel_test.broadcast_new_game.no_context"/>
      open_game = Factory.struct_for(:game, %{current_phase: :joining}) # <label id="code.testing_phoenix.channels.lobby_channel_test.broadcast_new_game.open_game"/>

      assert :ok = LobbyChannel.broadcast_new_game(open_game) # <label id="code.testing_phoenix.channels.lobby_channel_test.broadcast_new_game.exercise"/>

      assert_broadcast("new_game_created", broadcast_payload) # <label id="code.testing_phoenix.channels.lobby_channel_test.broadcast_new_game.assert_broadcast"/>
      assert broadcast_payload == %{game_id: open_game.id} # <label id="code.testing_phoenix.channels.lobby_channel_test.broadcast_new_game.assert_payload"/>

      assert Jason.encode!(broadcast_payload) # <label id="code.testing_phoenix.channels.lobby_channel_test.broadcast_new_game.check_serializable"/>
    end
    # END:happy_path

    for non_open_phase <- NotSkull.GameEngine.phases() -- [:joining] do
      test "error: returns error, does not broadcast when game phase is #{non_open_phase}" do
        current_phase = unquote(non_open_phase)
        open_game = Factory.struct_for(:game, %{current_phase: current_phase})

        assert :error = LobbyChannel.broadcast_new_game(open_game)

        refute_broadcast("new_game_created", _broadcast_payload)
      end
    end
# START:file_and_setup
  end
end
# END:file_and_setup
