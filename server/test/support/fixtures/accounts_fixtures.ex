defmodule Tostada.AccountsFixtures do
  @moduledoc """
  Test helpers for creating entities via the `Tostada.Accounts` context.
  """

  alias Tostada.Accounts

  def unique_user_email, do: "user#{System.unique_integer([:positive])}@example.com"
  def unique_display_name, do: "user#{System.unique_integer([:positive])}"
  def valid_user_password, do: "hello world!!"

  def valid_user_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      email: unique_user_email(),
      password: valid_user_password(),
      display_name: unique_display_name()
    })
  end

  def unconfirmed_user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> valid_user_attributes()
      |> Accounts.register_user()

    user
  end

  def user_fixture(attrs \\ %{}) do
    user = unconfirmed_user_fixture(attrs)
    {:ok, user} = Accounts.confirm_user(user)
    user
  end

  def extract_user_token(fun) do
    {:ok, captured_email} = fun.(&"[TOKEN]#{&1}[TOKEN]")
    [_, token | _] = String.split(captured_email.text_body, "[TOKEN]")
    token
  end
end
