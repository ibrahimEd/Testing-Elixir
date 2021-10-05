defmodule NotSkull.Repo do
  use Ecto.Repo,
    otp_app: :not_skull,
    adapter: Ecto.Adapters.Postgres
end
