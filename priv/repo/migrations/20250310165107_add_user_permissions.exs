defmodule BlogPost.Repo.Migrations.AddUserPermissions do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :permission_level, :integer, default: 0, null: false
    end
  end
end
