# START:file_new_and_create
defmodule NotSkullWeb.UserController do
  use NotSkullWeb, :controller

  alias NotSkull.Accounts
  alias NotSkull.Accounts.User
  alias NotSkull.ExternalServices.Email
# END:file_new_and_create

  def show(conn, %{"id" => user_id}) do
    with {:ok, session_user_id} <- user_id_from_session(conn),
         {true, _, _} <-
           {session_user_id == user_id, session_user_id, :check_ids_match},
         {:ok, user} <- Accounts.get_user_by_id(user_id) do
      render(conn, "show.html", user: user)
    else
      {false, session_user_id, :check_ids_match} ->
        conn
        |> put_flash(:error, "You are not authorized to access that page.")
        |> redirect(to: Routes.user_path(conn, :show, session_user_id))

      {:error, :not_found} ->
        conn
        |> put_flash(:error, "You are not logged in.")
        |> redirect(to: Routes.session_path(conn, :new))
    end
  end

# START:file_new_and_create
  def new(conn, _params) do
    user = User.create_changeset(%{})
    render(conn, "new.html", changeset: user)
  end

# START:only_create
  def create(conn, %{"user" => user_params}) do
    case Accounts.create_user(user_params) do
      {:ok, user} ->
        Email.send_welcome(user)

        conn
        |> put_session(:user_id, user.id)
        |> put_flash(:info, "Your account was created successfully!")
        |> redirect(to: Routes.user_path(conn, :show, user))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end
# END:only_create

# END:file_new_and_create
  def edit(conn, _params) do
    with {:ok, user_id} <- user_id_from_session(conn),
         {:ok, user} <- Accounts.get_user_by_id(user_id),
         changeset <- User.update_changeset(user, %{}) do
      render(conn, "edit.html", changeset: changeset, user: user)
    end
  end

  def update(conn, %{"id" => user_id, "user" => params}) do
    {:ok, user} = Accounts.get_user_by_id(user_id)

    case Accounts.update_user(user, params) do
      {:ok, user} ->
        conn
        |> put_flash(:info, "Update successful!")
        |> redirect(to: Routes.user_path(conn, :show, user))

      {:error, changeset} ->
        render(conn, "edit.html", changeset: changeset, user: user)
    end
  end

  defp user_id_from_session(conn) do
    if user = get_session(conn, :user_id) do
      {:ok, user}
    else
      {:error, :not_found}
    end
  end
# START:file_new_and_create
end
# END:file_new_and_create
