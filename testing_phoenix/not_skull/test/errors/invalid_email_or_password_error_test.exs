defmodule NotSkull.Errors.InvalidEmailOrPasswordErrorTest do
  use ExUnit.Case

  alias NotSkull.Errors.InvalidEmailOrPasswordError

  describe "exception/1" do
    test "success for an empty message" do
      error = InvalidEmailOrPasswordError.exception()

      assert %NotSkull.Errors.InvalidEmailOrPasswordError{
               message: "invalid email or password",
               plug_status: 401
             } == error
    end

    test "success with message passed" do
      message = "I'm a custom message"
      error = InvalidEmailOrPasswordError.exception(message: message)

      assert %NotSkull.Errors.InvalidEmailOrPasswordError{
               message: message,
               plug_status: 401
             } == error
    end
  end
end
