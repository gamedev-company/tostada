# Script for populating the database with minimal seed data.
#
# Run with: mix run priv/repo/seeds.exs

alias Tostada.Accounts
alias Tostada.Repo
alias Tostada.Accounts.User

email = System.get_env("SEED_ADMIN_EMAIL")
password = System.get_env("SEED_ADMIN_PASSWORD")
display_name = System.get_env("SEED_ADMIN_DISPLAY_NAME") || "admin"

if email && password do
  case Accounts.register_user(%{email: email, password: password, display_name: display_name}) do
    {:ok, user} ->
      user
      |> User.admin_changeset(%{is_admin: true})
      |> Repo.update()

      IO.puts("Seeded admin user: #{email}")

    {:error, changeset} ->
      IO.inspect(changeset.errors, label: "Failed to seed admin user")
  end
else
  IO.puts("No SEED_ADMIN_EMAIL/SEED_ADMIN_PASSWORD set; skipping admin seed")
end
