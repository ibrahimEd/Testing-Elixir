defmodule NotSkullWeb.JsonApi.LoginController do
  @moduledoc false

  use NotSkullWeb, :controller

  alias NotSkull.{Accounts, JWTUtility}
  alias NotSkull.Errors.InvalidEmailOrPasswordError

  def login(conn, params) do
    with {:ok, email} <- info_from_params(params, "email"),
         {:ok, password} <- info_from_params(params, "password"),
         {:ok, user} <- Accounts.get_user_by_credentials(email, password) do
      conn
      |> put_status(200)
      |> json(%{data: %{token: JWTUtility.jwt_for_user(user.id)}})
    else
      {:error, error} ->
        conn
        |> put_status(401)
        |> json(%{errors: [%{detail: error.message}]})
    end
  end

  defp info_from_params(params, key) do
    if value = get_in(params, ["auth", key]) do
      {:ok, value}
    else
      {:error,
       InvalidEmailOrPasswordError.exception(
         message: "#{key} is required to authenticate"
       )}
    end
  end
end
