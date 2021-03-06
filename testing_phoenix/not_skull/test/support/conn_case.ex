defmodule NotSkullWeb.ConnCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a connection.

  Such tests rely on `Phoenix.ConnTest` and also
  import other functionality to make it easier
  to build common data structures and query the data layer.

  Finally, if the test case interacts with the database,
  we enable the SQL sandbox, so changes done to the database
  are reverted at the end of every test. If you are using
  PostgreSQL, you can even run database tests asynchronously
  by setting `use NotSkullWeb.ConnCase, async: true`, although
  this option is not recommended for other databases.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      # Import conveniences for testing with connections
      import Ecto
      import Mox
      import NotSkullWeb.ConnCase
      import Phoenix.ConnTest
      import Plug.Conn
      import Support.AssertionHelpers
      import Support.JWTTestHelpers

      alias Support.Factory
      alias NotSkull.Repo
      alias NotSkullWeb.Router.Helpers, as: Routes

      # The default endpoint for testing
      @endpoint NotSkullWeb.Endpoint
    end
  end

  # START:conn_case_setup
  setup tags do
    Mox.verify_on_exit!() # <label id="code.testing_phoenix.conn_case.setup_block.mox_global"/>

    :ok = Ecto.Adapters.SQL.Sandbox.checkout(NotSkull.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(NotSkull.Repo, {:shared, self()}) # <label id="code.testing_phoenix.conn_case.setup_block.set_sandbox_mode"/>
    end

    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end

  # END:conn_case_setup

  # START:expect_mail_to
  def expect_email_to(expected_email_address) do
    Mox.expect(HttpClientMock, :request, fn method, # <label id="code.testing_phoenix.conn_case.expect_email_to"/>
                                            url,
                                            _headers,
                                            json_body,
                                            _opts ->
      assert method == :post
      assert url == "https://api.sendgrid.com/v3/mail/send"

      decoded_body = Jason.decode!(json_body)

      assert %{
               "personalizations" => [
                 %{
                   "to" => [
                     %{"email" => ^expected_email_address} # <label id="code.testing_phoenix.conn_case.pinned_value"/>
                   ]
                 }
               ]
             } = decoded_body
    end)
  end

  # END:expect_mail_to

  # START:flunk_if_email_is_sent
  def flunk_if_email_is_sent do
    Mox.stub(HttpClientMock, :request, fn _, _, _, _, _ ->
      flunk("An email should not have been sent.")
    end)
  end

  # END:flunk_if_email_is_sent

  def text_value_of_element(html, selector)
      when is_binary(html) do
    case Floki.parse_fragment!(html) |> Floki.find(selector) do
      [] ->
        flunk("Selector (#{inspect(selector)}) was not found in view.")

      [single_entry] ->
        Floki.text(single_entry)

      _list ->
        flunk("Selector isn't specific enough. It was found more than once.")
    end
  end
end
