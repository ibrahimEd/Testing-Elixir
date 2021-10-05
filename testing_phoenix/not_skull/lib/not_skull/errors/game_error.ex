defmodule NotSkull.Errors.GameError do
  @moduledoc false

  @type t :: %__MODULE__{}

  defexception message: ""

  def exception(opts \\ []) do
    message =
      Keyword.get(opts, :message, "Something went wrong with the game.")

    %__MODULE__{message: message}
  end
end
