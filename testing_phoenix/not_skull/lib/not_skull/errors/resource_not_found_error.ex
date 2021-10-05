defmodule NotSkull.Errors.ResourceNotFoundError do
  defexception message: "Resource not found", plug_status: 404

  def exception(opts) do
    resource = Keyword.fetch!(opts, :resource)
    id = Keyword.fetch!(opts, :id)

    %__MODULE__{message: "#{resource} not found for #{id}"}
  end
end
