defmodule NotSkullWeb.LobbyController do
  use NotSkullWeb, :controller
  alias NotSkull.ActiveGames

  def new(conn, _params) do
    with {:ok, user_id} <- get_user_from_session(conn),
         {:ok, %NotSkull.Accounts.User{} = user} <-
           NotSkull.Accounts.get_user_by_id(user_id) do
      player = %NotSkull.GameEngine.Player{
        name: user.name,
        id: user.id
      }

      {:ok, game} = ActiveGames.new_game(players: [player])

      NotSkullWeb.Endpoint.broadcast!("lobby:lobby", "new_game_created", %{game_id: game.id})

      redirect(conn, to: "/game?game_id=#{game.id}")
    end
  end

  defp get_user_from_session(conn) do
    if user = get_session(conn, :user_id) do
      {:ok, user}
    else
      {:error, :not_found}
    end
  end
end
