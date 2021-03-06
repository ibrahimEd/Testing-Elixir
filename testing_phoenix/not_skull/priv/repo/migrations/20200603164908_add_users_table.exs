defmodule NotSkull.Repo.Migrations.AddUsersTable do
  use Ecto.Migration

  def change do
    create table(:users, primary_key: false) do
      add(:id, :uuid, primary_key: true)
      add(:email, :string, null: false)
      add(:name, :string, null: false)
      add(:password, :string, null: false)

      timestamps(type: :utc_datetime_usec)
    end

    create(unique_index(:users, [:email]))
  end
end
