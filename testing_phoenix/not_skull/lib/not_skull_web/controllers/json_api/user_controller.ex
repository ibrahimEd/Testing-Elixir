# START:file_and_update
defmodule NotSkullWeb.JsonApi.UserController do
  @moduledoc false

  use NotSkullWeb, :controller

  alias NotSkull.Accounts

  # END:file_and_update
  alias NotSkull.ExternalServices.Email

  def create(conn, params) do
    case Accounts.create_user(params) do
      {:ok, user} ->
        Email.send_welcome(user)

        conn
        |> put_status(201)
        |> json(user_map_from_struct(user))

      {:error, error_changeset} ->
        conn
        |> put_status(422)
        |> json(errors_from_changset(error_changeset))
    end
  end

  # START:file_and_update
  def update(conn, params) do
    with {:ok, user} <- Accounts.get_user_by_id(params["id"]), # <label id="code.testing_phoenix.json_api.user_controller.update.with_statement"/>
         {:ok, updated_user} <- Accounts.update_user(user, params) do
      conn # <label id="code.testing_phoenix.json_api.user_controller.update.success_block"/>
      |> put_status(200)
      |> json(user_map_from_struct(updated_user))
    else
      {:error, error_changeset} ->
        conn # <label id="code.testing_phoenix.json_api.user_controller.update.error_handling"/>
        |> put_status(422)
        |> json(errors_from_changset(error_changeset))
    end
  end

  defp user_map_from_struct(user) do
    user
    |> Map.from_struct()
    |> Map.drop([:__struct__, :__meta__])
  end

  defp errors_from_changset(changeset) do
    serializable_errors =
      for {field, {message, _}} <- changeset.errors,
          do: %{"field" => to_string(field), "message" => message}

    %{errors: serializable_errors}
  end

  # END:file_and_update
end
