defmodule NotSkullWeb.UserSocket do
  use Phoenix.Socket
  alias NotSkull.{Accounts, JWTUtility}
  require Logger

  channel "lobby:*", NotSkullWeb.LobbyChannel

  @impl true
  def connect(%{"token" => token}, socket, _connect_info) do
    jwt = URI.decode_www_form(token)

    with {:ok, user_id} <- JWTUtility.user_id_from_jwt(jwt), # <label id="code.testing_phoenix.channels.user_socket.connect.jwt"/>
         {:ok, _valid_user} <- Accounts.get_user_by_id(user_id) do # <label id="code.testing_phoenix.channels.user_socket.connect.check_user"/>
      socket = assign(socket, :user_id, user_id) # <label id="code.testing_phoenix.channels.user_socket.connect.assigns"/>
      {:ok, socket}
    else
      something_else ->
        Logger.warn(inspect(something_else))
        :error
    end
  end

  def connect(_, _socket, _connect_info), do: :error

  @impl true
  def id(socket), do: "user_socket:#{socket.assigns.user_id}" # <label id="code.testing_phoenix.channels.user_socket.id_function"/>
end
