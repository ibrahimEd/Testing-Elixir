defmodule MyApp.Accounts do
  @moduledoc false
  alias MyApp.Repo
  alias MyApp.Accounts.User
  alias MyApp.ExternalServices.Email

  def create_user(params, emailer \\ Email) do
    result =
      params
      |> User.create_changeset()
      |> Repo.insert()

    case result do
      {:ok, new_user} ->
        :ok = emailer.send_welcome(new_user)
        {:ok, new_user}

      {:error, changeset} ->
        {:error, changeset}
    end
  end
end
