defmodule NotSkull.ExternalServices.Email do
  @http_client Application.get_env(
                 :not_skull,
                 :http_client,
                 NotSkull.HTTPClient
               )
  @sendgrid_api_key Application.get_env(:not_skull, :email_api_key)
  @sendgrid_uri "https://api.sendgrid.com/v3/mail/send"
  @email_from_address Application.get_env(:not_skull, :email_from_address)

  def send_welcome(user) do
    headers = [
      {"Authorization", "Bearer #{@sendgrid_api_key}"},
      {"Content-Type", "application/json"}
    ]

    email_body = "You have been added to NotSkull. Welcome."
    email_subject = "Welcome to NotSkull"
    body = email_body(user.email, email_subject, email_body)
    @http_client.request(:post, @sendgrid_uri, headers, body, [])
  end

  defp email_body(recipient_email, subject, email_body) do
    %{
      "content" => [
        %{"type" => "text/plain", "value" => email_body}
      ],
      "from" => %{"email" => @email_from_address},
      "personalizations" => [
        %{
          "to" => [
            %{"email" => recipient_email}
          ]
        }
      ],
      "subject" => subject
    }
    |> Jason.encode!()
  end
end
