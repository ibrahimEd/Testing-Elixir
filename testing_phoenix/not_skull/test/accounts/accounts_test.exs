defmodule MyApp.AccountsTest do
  use MyApp.DataCase
  alias Ecto.Changeset

  describe "create_user/1" do
    test "success: it creates and returns a user when given valid params" do
      params = Factory.string_params(:user)
      test_pid = self()

      function_double = fn user ->
        send(test_pid, {:user, user})
        :ok
      end

      assert {:ok, %User{} = returned_user} =
               Accounts.create_user(params, function_double)

      user_from_db = Repo.get(User, returned_user.id)

      assert user_from_db == returned_user

      assert_values_for(
        expected: {params, :string_keys},
        actual: user_from_db,
        fields: fields_for(User) -- db_assigned_fields(plus: [:password])
      )

      error_message = "email wasn't sent or was sent to wrong user"
      assert_receive({:user, ^returned_user}, 500, error_message)
    end
  end
end
