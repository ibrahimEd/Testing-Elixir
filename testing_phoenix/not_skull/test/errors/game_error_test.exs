defmodule NotSkull.Errors.GameErrorTest do
  use ExUnit.Case

  alias NotSkull.Errors.GameError

  describe "exception/1" do
    test "success for an empty message" do
      error = GameError.exception()

      assert %NotSkull.Errors.GameError{
               message: "Something went wrong with the game."
             } == error
    end

    test "success with message passed" do
      message = "I'm a custom message"
      error = GameError.exception(message: message)

      assert %NotSkull.Errors.GameError{
               message: message
             } == error
    end
  end
end
