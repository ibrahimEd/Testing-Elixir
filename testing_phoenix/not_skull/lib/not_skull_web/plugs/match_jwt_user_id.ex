defmodule NotSkullWeb.Plugs.MatchJWTUserId do
  @moduledoc false

  def init(options) do
    options
  end

  def call(conn, _opts) do
    conn = Plug.Conn.fetch_query_params(conn)
    user_id_from_jwt = conn.params["context_id"]
    user_id_from_path = conn.path_params["id"]

    if user_id_from_jwt == user_id_from_path do
      conn
    else
      error =
        Jason.encode!(%{
          "errors" => [
            %{
              field: "token",
              message: "You are not authorized for that action."
            }
          ]
        })

      conn
      |> Plug.Conn.put_resp_content_type("application/json")
      |> Plug.Conn.resp(403, error)
      |> Plug.Conn.halt()
    end
  end
end
