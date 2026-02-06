defmodule TostadaWeb.UserSessionHTML do
  use TostadaWeb, :html

  embed_templates "user_session_html/*"

  defp local_mail_adapter? do
    Application.get_env(:tostada, Tostada.Mailer)[:adapter] == Swoosh.Adapters.Local
  end
end
