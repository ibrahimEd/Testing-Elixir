defmodule NotSkullWeb.LobbyChannel do
  use NotSkullWeb, :channel

  alias NotSkull.GameEngine.Game

  @impl true
  def join("lobby:lobby", _payload, socket) do # <label id="code.testing_phoenix.channels.lobby_channel.join"/>
    {:ok, socket}
  end

  @spec broadcast_new_game(Game.t()) :: :ok | :error
  def broadcast_new_game(%Game{current_phase: :joining} = game) do
    NotSkullWeb.Endpoint.broadcast!("lobby:lobby", "new_game_created", %{ # <label id="code.testing_phoenix.channels.lobby_channel.broadcast_new_game"/>
      game_id: game.id
    })
  end

  def broadcast_new_game(_) do
    :error
  end
end
