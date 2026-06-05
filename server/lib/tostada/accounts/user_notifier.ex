defmodule Tostada.Accounts.UserNotifier do
  @moduledoc """
  Email notifications for user accounts.

  In dev the Swoosh local adapter is used — view sent emails at
  http://localhost:4000/dev/mailbox. Configure a real SMTP/SES/Postmark
  adapter in `config/runtime.exs` for production.
  """
  import Swoosh.Email

  alias Tostada.Mailer

  defp deliver(recipient, subject, body) do
    email =
      new()
      |> to(recipient)
      |> from({"Tostada", "contact@example.com"})
      |> subject(subject)
      |> text_body(body)

    with {:ok, _metadata} <- Mailer.deliver(email) do
      {:ok, email}
    end
  end

  @doc """
  Deliver instructions to reset a user password.
  """
  def deliver_reset_password_instructions(user, url) do
    deliver(user.email, "Reset password instructions", """

    ==============================

    Hi #{user.email},

    You can reset your password by visiting the URL below:

    #{url}

    If you didn't request this change, please ignore this.

    ==============================
    """)
  end
end
