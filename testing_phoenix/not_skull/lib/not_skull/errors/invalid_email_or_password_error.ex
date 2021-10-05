defmodule NotSkull.Errors.InvalidEmailOrPasswordError do
  @moduledoc false

  defexception message: "", plug_status: 401

  def exception(opts \\ []) do
    message = Keyword.get(opts, :message, "invalid email or password")
    %__MODULE__{message: message}
  end
end
