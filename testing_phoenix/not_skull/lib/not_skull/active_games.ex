defmodule NotSkull.ActiveGames do
  use GenServer
  alias NotSkull.GameEngine
  alias NotSkull.Errors.GameError

  @game_engine Application.get_env(:not_skull, :game_engine, GameEngine)
  # Public Interface

  def new_game(overrides \\ []) do
    GenServer.call(__MODULE__, {:new, overrides})
  end

  def join(game_id, player) do
    GenServer.call(__MODULE__, {:join, game_id, player})
  end

  def start(game_id, player) do
    GenServer.call(__MODULE__, {:start, game_id, player})
  end

  def move(game_id, move) do
    GenServer.call(__MODULE__, {:move, game_id, move})
  end

  def get_game_by_id(game_id) do
    GenServer.call(__MODULE__, {:fetch, game_id})
  end

  def all do
    GenServer.call(__MODULE__, :all)
  end

  # GenServer bits

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init([]) do
    {:ok, %{}}
  end

  def handle_call({:new, overrides}, _from, games_by_id) do
    {:ok, new_game} = GameEngine.new_game(overrides)

    updated_games_by_id = Map.put(games_by_id, new_game.id, new_game)
    {:reply, {:ok, new_game}, updated_games_by_id}
  end

  def handle_call({:join, game_id, player}, _from, games_by_id) do
    # get what we need from state
    game = Map.get(games_by_id, game_id)

    # call to logic module(s)
    {status, game} = result = GameEngine.join(game, player)

    # define new state
    updated_games_by_id =
      if status == :ok do
        Map.put(games_by_id, game_id, game)
      else
        games_by_id
      end

    # respond and set new state
    {:reply, result, updated_games_by_id}
  end

  def handle_call({:start, game_id, player}, _from, games_by_id) do
    # get what we need from state
    game = Map.get(games_by_id, game_id)

    # call to logic module(s)
    {status, game} = result = GameEngine.start(game, player)

    # define new state
    updated_games_by_id =
      if status == :ok do
        Map.put(games_by_id, game_id, game)
      else
        games_by_id
      end

    # respond and set new state
    {:reply, result, updated_games_by_id}
  end

  def handle_call({:move, game_id, move}, _from, games_by_id) do
    {:ok, game} = fetch_game_by_id(game_id, games_by_id)

    {status, game} = result = @game_engine.update_game(game, move)

    updated_games_by_id =
      if status == :ok do
        Map.put(games_by_id, game_id, game)
      else
        games_by_id
      end

    {:reply, result, updated_games_by_id}
  end

  def handle_call({:fetch, game_id}, _from, games_by_id) do
    result = fetch_game_by_id(game_id, games_by_id)

    {:reply, result, games_by_id}
  end

  def handle_call(:all, _from, games_by_id) do
    {:reply, Map.keys(games_by_id), games_by_id}
  end

  defp fetch_game_by_id(game_id, games_by_id) do
    if game = Map.get(games_by_id, game_id) do
      {:ok, game}
    else
      {:error,
       GameError.exception(
         message: "That game doesn't exist or is no longer active."
       )}
    end
  end
end
