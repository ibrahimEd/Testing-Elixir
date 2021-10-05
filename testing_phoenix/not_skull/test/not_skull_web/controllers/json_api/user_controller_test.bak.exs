# START:file_and_setup_for_update
defmodule NotSkullWeb.JsonApi.UserControllerTest do
  use NotSkullWeb.ConnCase, async: false  # <label id="code.testing_phoenix.json_api.user_controller_test.using_conn_case"/>

  alias NotSkull.Accounts.User

# END:file_and_setup_for_update

  describe "POST /users" do
    test "success: creates_user, redirects to show page when user is created",
         %{conn: conn} do
      params = Factory.string_params(:user)

      # welcome email should get sent
      expect_email_to(params["email"])

      conn = post(conn, "/api/users", params)

      assert body = json_response(conn, 201)

      user_from_db = Repo.get(User, body["id"])

      assert_values_for(
        expected: {params, :string_keys},
        actual: user_from_db,
        fields: fields_for(User) -- db_assigned_fields(plus: [:password])
      )
    end

    test "error: does not insert, returns erros when given invalid attributes",
         %{
           conn: conn
         } do
      flunk_if_email_is_sent()

      expected_user_count = Repo.all(User) |> Enum.count()
      conn = post(conn, "/api/users", user: %{})

      assert body = json_response(conn, 422)

      actual_errors = body["errors"]
      refute Enum.empty?(actual_errors)

      expected_error_keys = ["field", "message"]

      for error <- actual_errors do
        assert_unordered_lists_are_equal(
          actual: Map.keys(error),
          expected: expected_error_keys
        )
      end

      assert Repo.all(User) |> Enum.count() == expected_user_count,
             "There should have been no records inserted during this test."
    end
  end

# START:file_and_setup_for_update
  describe "PUT /api/users/:id" do
    setup context do
      {:ok, user} = Factory.insert(:user)

      conn_with_token = # <label id="code.testing_phoenix.json_api.user_controller_test.update.setup_block"/>
        put_req_header(  # <label id="code.testing_phoenix.json_api.user_controller_test.update.put_req_header"/>
          context.conn,
          "authorization",
          "Bearer " <> sign_jwt(user.id)  # <label id="code.testing_phoenix.json_api.user_controller_test.update.sign_jwt"/>
        )

      Map.merge(context, %{user: user, conn_with_token: conn_with_token})
    end
# END:file_and_setup_for_update

# START:update_happy_path
    test "success: updates db returns record with good params", %{
      conn_with_token: conn_with_token,
      user: existing_user
    } do
      new_name = "#{existing_user.name}-updated"

      conn =
        put(conn_with_token, "/api/users/#{existing_user.id}", %{
          name: new_name
        })

      assert parsed_return = json_response(conn, 200)

      user_from_db = Repo.get(User, existing_user.id)

      assert_values_for( # <label id="code.testing_phoenix.json_api.user_controller_test.update.happy_path.first_assert_values_for"/>
        expected: %{existing_user | name: new_name},# <label id="code.testing_phoenix.json_api.user_controller_test.update.happy_path.expected"/>
        actual: user_from_db,
        fields: fields_for(User) -- [:updated_at] # <label id="code.testing_phoenix.json_api.user_controller_test.update.happy_path.fields_for"/>
      )

      assert DateTime.to_unix(user_from_db.updated_at, :microsecond) > # <label id="code.testing_phoenix.json_api.user_controller_test.update.happy_path.checking_updated_at"/>
               DateTime.to_unix(existing_user.updated_at, :microsecond)

      # checking that the updated record is what is returned from endpoint
      assert_values_for(  # <label id="code.testing_phoenix.json_api.user_controller_test.update.happy_path.second_assert_values_for"/>
        expected: user_from_db,
        actual: {parsed_return, :string_keys},
        fields: fields_for(User),
        opts: [convert_dates: true]
      )
    end
# END:update_happy_path

# START:params_error_test

    test "error: does not update, returns errors when given invalid attributes",
         %{
           conn_with_token: conn_with_token,  # <label id="code.testing_phoenix.json_api.user_controller_test.update.param_error.accepting_context"/>
           user: existing_user
         } do
      conn =
        put(conn_with_token, "/api/users/#{existing_user.id}", %{name: ""})  # <label id="code.testing_phoenix.json_api.user_controller_test.update.param_error.exercise"/>

      assert body = json_response(conn, 422) # <label id="code.testing_phoenix.json_api.user_controller_test.update.param_error.json_response"/>

      user_from_db = Repo.get(User, existing_user.id)
      assert user_from_db == existing_user  # <label id="code.testing_phoenix.json_api.user_controller_test.update.param_error.check_side_effects"/>

      actual_errors = body["errors"]
      refute Enum.empty?(actual_errors)

      expected_error_keys = ["field", "message"]

      for error <- actual_errors do  # <label id="code.testing_phoenix.json_api.user_controller_test.update.param_error.error_shape"/>
        assert_unordered_lists_are_equal(
          actual: Map.keys(error),
          expected: expected_error_keys
        )
      end
    end

# END:params_error_test

# START:valid_jwt_plug_test
    test "auth error: returns 401 when valid jwt isn't in headers", %{
      conn: conn,  # <label id="code.testing_phoenix.json_api.user_controller_test.update.jwt_plug.unsigned_conn"/>
      user: existing_user
    } do
      conn =
        put(conn, "/api/users/#{existing_user.id}", %{ # <label id="code.testing_phoenix.json_api.user_controller_test.update.jwt_plug.exercise"/>
          name: "#{existing_user.name}-updated"
        })

      assert body = json_response(conn, 401) # <label id="code.testing_phoenix.json_api.user_controller_test.update.jwt_plug.assert_and_check_http"/>

      assert %{ # <label id="code.testing_phoenix.json_api.user_controller_test.update.jwt_plug.errors"/>
               "errors" => [
                 %{"message" => "Invalid token.", "field" => "token"}
               ]
             } == body

      user_from_db = Repo.get(User, existing_user.id)  # <label id="code.testing_phoenix.json_api.user_controller_test.update.jwt_plug.verify_no_side_effect"/>

      assert_values_for(
        expected: existing_user,
        actual: user_from_db,
        fields: fields_for(User)
        )
    end
# END:valid_jwt_plug_test

# START:id_match_plug_test
    test "auth error: returns 403 when path and jwt user ids don't match",
         %{
           conn_with_token: conn_with_token,
           user: existing_user
         } do
          conn =
            put(conn_with_token, "/api/users/#{Factory.uuid()}", %{
              name: "#{existing_user.name}-updated"
            })

      assert body = json_response(conn, 403)

      assert %{
               "errors" => [
                 %{
                   "message" => "You are not authorized for that action.",
                   "field" => "token"
                 }
               ]
             } == body

      user_from_db = Repo.get(User, existing_user.id)

      assert_values_for(
        expected: existing_user,
        actual: user_from_db,
        fields: fields_for(User)
        )
    end
# START:id_match_plug_test
# START:file_and_setup_for_update
  end
end
# END:file_and_setup_for_update
