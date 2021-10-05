defmodule NotSkull.Errors.ResourceNotFoundErrorTest do
  use ExUnit.Case

  alias NotSkull.Errors.ResourceNotFoundError

  describe "exception/1" do
    test "success" do
      id = Enum.random(1..1000)
      resource = Enum.random(["User", "Business profile"])

      error = ResourceNotFoundError.exception(resource: resource, id: id)

      assert 404 == error.plug_status
      assert "#{resource} not found for #{id}" == error.message
    end
  end
end
