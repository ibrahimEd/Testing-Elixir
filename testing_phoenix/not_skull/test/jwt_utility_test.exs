defmodule NotSkull.JWTUtilityTest do
  use ExUnit.Case, async: true
  alias Support.{Factory, JWTTestHelpers}
  alias NotSkull.JWTUtility

  # Yes, the JWTUtility and the JWTTestHelpers are almost the
  # same logic. These tests are here to prevent regressions.

  describe "jwt_for_user/1" do
    test "success: it returns a user_id from a valid JWT" do
      user_id = Factory.uuid()

      jwt = JWTUtility.jwt_for_user(user_id)

      {:ok, claims} = JWTTestHelpers.claims_from_jwt(jwt)
      assert claims["cid"] == user_id
    end
  end

  describe "user_id_from_jwt/1" do
    test "success: returns ok tuple with id" do
      user_id = Factory.uuid()
      jwt = JWTTestHelpers.sign_jwt(user_id)

      assert {:ok, ^user_id} = JWTUtility.user_id_from_jwt(jwt)
    end

    test "error: returns error if no id" do
      bad_jwt = JWTTestHelpers.sign_jwt(%{"boo" => "hello"})

      assert {:error, :jwt_missing_user_id} =
               JWTUtility.user_id_from_jwt(bad_jwt)
    end

    test "error: returns error if invalid jwt" do
      bad_jwt = Factory.uuid()
      assert {:error, :invalid_jwt} = JWTUtility.user_id_from_jwt(bad_jwt)
    end
  end
end
