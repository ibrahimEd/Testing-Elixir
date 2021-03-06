# START:file_only
defmodule NotSkullWeb.UserControllerTest do
  use NotSkullWeb.ConnCase, async: false

  alias NotSkull.Accounts.User
# END:file_only

# START:new
  describe "GET /users/new" do # <label id="code.testing_phoenix.html_api.user_controller_test.new.describe"/>
    test "success: it renders the form", %{conn: conn} do  # <label id="code.testing_phoenix.html_api.user_controller_test.new.accepting_context"/>
      conn = get(conn, Routes.user_path(conn, :new))  # <label id="code.testing_phoenix.html_api.user_controller_test.new.exercise"/>

      assert response = html_response(conn, 200)  # <label id="code.testing_phoenix.html_api.user_controller_test.new.decode_html"/>

      assert response =~ "Create a new account"  # <label id="code.testing_phoenix.html_api.user_controller_test.new.assert_on_body"/>
    end
  end
# END:new

# START:create_describe_and_happy_path
  describe "POST /users" do
    test "success: creates_user, redirects to show page when user is created",
         %{conn: conn} do
      params = Factory.atom_params(:user) # <label id="code.testing_phoenix.html_api.user_controller_test.create.happy.valid_params"/>

      expect_email_to(params.email) # <label id="code.testing_phoenix.html_api.user_controller_test.create.happy.email_mock"/>

      conn = post(conn, Routes.user_path(conn, :create), user: params)

      assert %{id: id} = redirected_params(conn) # <label id="code.testing_phoenix.html_api.user_controller_test.create.happy.redirected_params"/>
      assert redirected_to(conn) == Routes.user_path(conn, :show, id) # <label id="code.testing_phoenix.html_api.user_controller_test.create.happy.assert_redirected"/>

      assert %{"user_id" => ^id} = get_session(conn) # <label id="code.testing_phoenix.html_api.user_controller_test.create.happy.assert_on_session"/>
      assert get_flash(conn, :info) =~ "success" # <label id="code.testing_phoenix.html_api.user_controller_test.create.happy.assert_on_flash"/>

      user_from_db = Repo.get(User, id) # <label id="code.testing_phoenix.html_api.user_controller_test.create.happy.assert_values_for"/>

      fields_to_check = Map.keys(params) -- [:password]

      assert_values_for(
        expected: params,
        actual: user_from_db,
        fields: fields_to_check
      )

      assert user_from_db.password
    end
    # END:create_describe_and_happy_path
    # START:error_case
    test "error: does not insert, redirects to 'new' page w/invalid attributes",
         %{
           conn: conn
         } do
      flunk_if_email_is_sent()  # <label id="code.testing_phoenix.html_api.user_controller_test.create.sad.email_mock"/>

      expected_user_count = Repo.all(User) |> Enum.count() # <label id="code.testing_phoenix.html_api.user_controller_test.create.sad.user_count_part_one"/>
      conn = post(conn, Routes.user_path(conn, :create), user: %{})

      assert html = html_response(conn, 200)

      parsed_html = Floki.parse_document!(html)
      for field <- ["name", "email", "password"] do # <label id="code.testing_phoenix.html_api.user_controller_test.create.sad.assert_error"/>
        # using <> so that the first #(indicating an id) is easy to read
        field_as_id = "#" <> "#{field}-error"
        span = Floki.find(parsed_html, field_as_id)
        assert Floki.text(span) == "can't be blank" # <label id="code.testing_phoenix.html_api.user_controller_test.create.sad.floki_text"/>
      end

      assert Repo.all(User) |> Enum.count() == expected_user_count, # <label id="code.testing_phoenix.html_api.user_controller_test.create.sad.user_count_part_two"/>
             "There should have been no records inserted during this test."
    end
    # END:error_case
    # START:create_describe_and_happy_path
  end
  # END:create_describe_and_happy_path

  describe "GET /users/:id/edit" do
    setup [:create_user]

    test "success: it renders the form", %{conn: conn, user: existing_user} do
      conn =
        conn
        |> Plug.Test.init_test_session(%{user_id: existing_user.id})
        |> get(Routes.user_path(conn, :edit, existing_user))

      assert response = html_response(conn, 200)

      assert response =~ "Edit yourself"
    end
  end

  describe "PUT /users/:id" do
    setup [:create_user]

    test "success: redirects to show page after user has been updated", %{
      conn: conn,
      user: existing_user
    } do
      new_name = "#{existing_user.name}-updated"

      conn =
        put(conn, Routes.user_path(conn, :update, existing_user),
          user: %{name: new_name}
        )

      assert %{id: id} = redirected_params(conn)
      assert get_flash(conn, :info) == "Update successful!"

      assert redirected_to(conn) == Routes.user_path(conn, :show, id)

      user_from_db = Repo.get(User, existing_user.id)

      # fields we didn't test will be covered on unit testing
      assert_values_for(
        expected: %{existing_user | name: new_name},
        actual: user_from_db,
        fields: fields_for(User) -- [:updated_at, :password]
      )
    end

    test "error: redirects to the new page when given invald attributes", %{
      conn: conn,
      user: user
    } do
      conn =
        put(conn, Routes.user_path(conn, :update, user), user: %{name: ""})

      assert html = html_response(conn, 200)

      assert html =~ "Edit yourself"

      assert html =~
               "We found some problems when editing your account. Please try again."
    end
  end

  describe "GET /users/:id" do
    setup [:create_user]

    test "success: renders show page when user is logged in", %{
      conn: conn,
      user: user
    } do
      conn =
        conn
        |> Plug.Test.init_test_session(%{user_id: user.id})
        |> get(Routes.user_path(conn, :show, user))

      assert response = html_response(conn, 200)
      assert response =~ "Profile for: #{user.email}"
    end

    test "error: redirects to the login page when user isn't logged in", %{
      conn: conn,
      user: user
    } do
      conn = get(conn, Routes.user_path(conn, :show, user))

      assert redirected_to(conn) == Routes.session_path(conn, :new)

      assert get_flash(conn, :error) =~ "not logged in"
    end

    test "error: redirects to the login page when logged in user attempts to see other user",
         %{
           conn: conn,
           user: user
         } do
      conn =
        conn
        |> Plug.Test.init_test_session(%{user_id: user.id})
        |> get(Routes.user_path(conn, :show, Factory.uuid()))

      assert redirected_to(conn) == Routes.user_path(conn, :show, user.id)

      assert get_flash(conn, :error) =~
               "You are not authorized to access that page."
    end
  end

  defp create_user(context) do
    {:ok, user} =
      Factory.atom_params(:user)
      |> NotSkull.Accounts.User.create_changeset()
      |> Repo.insert()
    Map.put(context, :user, user)
  end
# START:file_only
end
# END:file_only
