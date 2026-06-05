defmodule Tostada.Accounts do
  @moduledoc """
  The Accounts context.

  Handles user registration, password authentication, password reset, and
  session-token issuance. No email confirmation flow — newly registered
  users are active immediately. The bcrypt + Phoenix.Token primitives stay
  on the server; client UIs are responsible for forms and routing.
  """

  import Ecto.Query, warn: false
  alias Tostada.Repo

  alias Tostada.Accounts.{User, UserToken, UserNotifier}

  ## Database getters

  @doc "Lists all users."
  @spec list_users() :: [User.t()]
  def list_users do
    Repo.all(User)
  end

  @doc "Gets a user by ID."
  def get_user(id), do: Repo.get(User, id)

  @doc "Gets a user by ID, raises if not found."
  def get_user!(id), do: Repo.get!(User, id)

  @doc "Gets a user by email."
  def get_user_by_email(email) when is_binary(email) do
    Repo.get_by(User, email: email)
  end

  @doc "Gets a user by email and password."
  def get_user_by_email_and_password(email, password)
      when is_binary(email) and is_binary(password) do
    user = Repo.get_by(User, email: email)
    if User.valid_password?(user, password), do: user
  end

  @doc "Changes a user (admin - display_name, is_admin only, no password)."
  @spec change_user(User.t(), map()) :: Ecto.Changeset.t()
  def change_user(%User{} = user, attrs \\ %{}) do
    User.admin_changeset(user, attrs)
  end

  @doc "Updates a user (admin - display_name, is_admin only, no password)."
  @spec update_user(User.t(), map()) :: {:ok, User.t()} | {:error, Ecto.Changeset.t()}
  def update_user(%User{} = user, attrs) do
    user
    |> User.admin_changeset(attrs)
    |> Repo.update()
  end

  @doc "Deletes a user."
  @spec delete_user(User.t()) :: {:ok, User.t()} | {:error, Ecto.Changeset.t()}
  def delete_user(%User{} = user) do
    Repo.delete(user)
  end

  ## User registration

  @doc """
  Registers a user with email, password, and display name.
  """
  def register_user(attrs) do
    %User{}
    |> User.registration_changeset(attrs)
    |> Repo.insert()
  end

  @doc "Returns a changeset for tracking user registration changes."
  def change_user_registration(%User{} = user, attrs \\ %{}, opts \\ []) do
    User.registration_changeset(user, attrs, Keyword.put(opts, :hash_password, false))
  end

  ## Password

  @doc "Returns a changeset for changing the user password."
  def change_user_password(user, attrs \\ %{}, opts \\ []) do
    User.password_changeset(user, attrs, Keyword.put(opts, :hash_password, false))
  end

  @doc "Updates the user password and invalidates all existing tokens."
  def update_user_password(user, attrs) do
    user
    |> User.password_changeset(attrs)
    |> update_user_and_delete_all_tokens()
  end

  ## Session

  @doc "Generates a session token."
  def generate_user_session_token(user) do
    {token, user_token} = UserToken.build_session_token(user)
    Repo.insert!(user_token)
    token
  end

  @doc """
  Gets the user with the given signed token.
  Returns `{user, token_inserted_at}` if valid, otherwise `nil`.
  """
  def get_user_by_session_token(token) do
    {:ok, query} = UserToken.verify_session_token_query(token)
    Repo.one(query)
  end

  @doc "Deletes the signed token with the given context."
  def delete_user_session_token(token) do
    Repo.delete_all(from(UserToken, where: [token: ^token, context: "session"]))
    :ok
  end

  ## Password reset

  @doc """
  Delivers a password reset email. The caller supplies a function that
  turns an encoded token into a URL the user can visit (in client UIs
  this points at the SPA's `/reset-password?token=…` route).

  Returns `{:ok, _email}` on send, `{:error, :invalid}` when the email
  doesn't belong to a user — by design we still respond identically to
  the client so an attacker can't enumerate accounts.
  """
  def deliver_user_reset_password_instructions(%User{} = user, reset_password_url_fun)
      when is_function(reset_password_url_fun, 1) do
    {encoded_token, user_token} = UserToken.build_email_token(user, "reset_password")
    Repo.insert!(user_token)
    UserNotifier.deliver_reset_password_instructions(user, reset_password_url_fun.(encoded_token))
  end

  @doc """
  Gets the user by reset password token.
  """
  def get_user_by_reset_password_token(token) do
    with {:ok, query} <- UserToken.verify_email_token_query(token, "reset_password"),
         %User{} = user <- Repo.one(query) do
      user
    else
      _ -> nil
    end
  end

  @doc """
  Resets the user password using the supplied attrs. Deletes all of the
  user's tokens (including the reset token) so old sessions are kicked.
  """
  def reset_user_password(user, attrs) do
    user
    |> User.password_changeset(attrs)
    |> update_user_and_delete_all_tokens()
  end

  ## Token helper

  defp update_user_and_delete_all_tokens(changeset) do
    Repo.transact(fn ->
      with {:ok, user} <- Repo.update(changeset) do
        tokens_to_expire = Repo.all_by(UserToken, user_id: user.id)
        Repo.delete_all(from(t in UserToken, where: t.id in ^Enum.map(tokens_to_expire, & &1.id)))
        {:ok, {user, tokens_to_expire}}
      end
    end)
  end
end
