defmodule Tostada.Accounts do
  @moduledoc """
  The Accounts context.

  Handles user registration, authentication, and account management.
  Password-based authentication only (no magic links).
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

  ## Settings

  @doc """
  Checks whether the user is in sudo mode.
  User is in sudo mode when last authenticated no more than 20 minutes ago.
  """
  def sudo_mode?(user, minutes \\ -20)

  def sudo_mode?(%User{authenticated_at: ts}, minutes) when is_struct(ts, DateTime) do
    DateTime.after?(ts, DateTime.utc_now() |> DateTime.add(minutes, :minute))
  end

  def sudo_mode?(_user, _minutes), do: false

  @doc "Returns a changeset for changing the user email."
  def change_user_email(user, attrs \\ %{}, opts \\ []) do
    User.email_changeset(user, attrs, opts)
  end

  @doc "Updates the user email using the given token."
  def update_user_email(user, token) do
    context = "change:#{user.email}"

    Repo.transact(fn ->
      with {:ok, query} <- UserToken.verify_change_email_token_query(token, context),
           %UserToken{sent_to: email} <- Repo.one(query),
           {:ok, user} <- Repo.update(User.email_changeset(user, %{email: email})),
           {_count, _result} <-
             Repo.delete_all(from(UserToken, where: [user_id: ^user.id, context: ^context])) do
        {:ok, user}
      else
        _ -> {:error, :invalid_token}
      end
    end)
  end

  @doc "Returns a changeset for changing the user password."
  def change_user_password(user, attrs \\ %{}, opts \\ []) do
    User.password_changeset(user, attrs, Keyword.put(opts, :hash_password, false))
  end

  @doc "Updates the user password."
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

  ## Confirmation

  @doc "Confirms a user account."
  def confirm_user(user) do
    user
    |> User.confirm_changeset()
    |> Repo.update()
  end

  @doc "Returns true if user is confirmed."
  def user_confirmed?(%User{confirmed_at: confirmed_at}), do: not is_nil(confirmed_at)

  @doc "Delivers confirmation instructions to the given user."
  def deliver_user_confirmation_instructions(%User{} = user, confirmation_url_fun)
      when is_function(confirmation_url_fun, 1) do
    if user.confirmed_at do
      {:error, :already_confirmed}
    else
      {encoded_token, user_token} = UserToken.build_email_token(user, "confirm")
      Repo.insert!(user_token)
      UserNotifier.deliver_confirmation_instructions(user, confirmation_url_fun.(encoded_token))
    end
  end

  @doc "Confirms a user by the given token."
  def confirm_user_by_token(token) do
    with {:ok, query} <- UserToken.verify_email_token_query(token, "confirm"),
         %User{} = user <- Repo.one(query),
         {:ok, user} <- confirm_user(user) do
      Repo.delete_all(from(UserToken, where: [user_id: ^user.id, context: "confirm"]))
      {:ok, user}
    else
      _ -> {:error, :invalid_token}
    end
  end

  @doc "Delivers email update instructions to the given user."
  def deliver_user_update_email_instructions(%User{} = user, current_email, update_email_url_fun)
      when is_function(update_email_url_fun, 1) do
    {encoded_token, user_token} = UserToken.build_email_token(user, "change:#{current_email}")
    Repo.insert!(user_token)
    UserNotifier.deliver_update_email_instructions(user, update_email_url_fun.(encoded_token))
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
