# START:file_only
defmodule NotSkullWeb.UserSocketTest do
  use NotSkullWeb.ChannelCase # <label id="code.testing_phoenix.channels.user_socket_test.channel_case"/>
  alias NotSkullWeb.UserSocket

  describe "connect/3" do
# END:file_only
# START:happy_path
    test "success: allows connection when passed a valid JWT for a real user" do
      {:ok, existing_user} = Factory.insert(:user)
      jwt = sign_jwt(existing_user.id)

      assert {:ok, socket} = connect(UserSocket, %{token: jwt}) # <label id="code.testing_phoenix.channels.user_socket_test.happy.connect"/>
      assert socket.assigns.user_id == existing_user.id # <label id="code.testing_phoenix.channels.user_socket_test.happy.assert_user_id"/>
      assert socket.id == "user_socket:#{existing_user.id}" # <label id="code.testing_phoenix.channels.user_socket_test.happy.assert_socket_id"/>
    end
# END:happy_path

# START:invalid_jwt
    @tag capture_log: true
    test "error: returns :error for an invalid JWT" do
      assert :error = connect(UserSocket, %{token: "bad_token"})
    end
# END:invalid_jwt

# START:invalid_user_id
    @tag capture_log: true
    test "error: returns :error if user doesn't exist" do
      jwt = sign_jwt(Factory.uuid())

      assert :error = connect(UserSocket, %{token: jwt})
    end
# END:invalid_user_id

# START:file_only
  end
end
# END:file_only
