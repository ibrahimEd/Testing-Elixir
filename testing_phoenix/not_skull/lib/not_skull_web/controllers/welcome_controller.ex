defmodule NotSkullWeb.WelcomeController do
  use NotSkullWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
