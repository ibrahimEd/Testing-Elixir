defmodule NotSkullWeb.FallbackController do
  use NotSkullWeb, :controller

  def call(conn, {:error, %{__exception__: true, message: message} = _error}) do
    conn
    |> put_flash(:error, message)
    |> redirect(to: Routes.session_path(conn, :new))
  end

  def call(conn, {context, {:error, %Ecto.Changeset{} = changeset}}) do
    errors =
      Enum.map(changeset.errors, fn {field, detail} ->
        %{
          field: field,
          message: render_detail(detail)
        }
      end)

    conn
    |> put_flash(:error, errors)
    |> render(to: error_route(conn, context))
  end

  defp error_route(conn, context) do
    routes = %{
      user_create: Routes.user_path(conn, :new)
    }

    Map.get(routes, context)
  end

  def render_detail({message, values}) do
    Enum.reduce(values, message, fn {k, v}, acc ->
      String.replace(acc, "%{#{k}}", to_string(v))
    end)
  end
end
