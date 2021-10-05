defmodule NotSkull.HTTPClient do
  @moduledoc false

  @callback request(term(), binary(), [], term(), []) ::
              {:ok, integer, list, binary}
              | {:ok, integer, list}
              | {:error, term()}

  @spec request(term(), binary(), [], term(), []) ::
          {:ok, integer, list, binary}
          | {:ok, integer, list}
          | {:error, term()}
  def request(method, url, headers, body, options) do
    :hackney.request(method, url, headers, body, options)
  end
end
