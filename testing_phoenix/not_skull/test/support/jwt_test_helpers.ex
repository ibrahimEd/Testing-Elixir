defmodule Support.JWTTestHelpers do
  def sign_jwt(user_id) when is_binary(user_id) do
    sign_jwt(%{"cid" => user_id})
  end

  def sign_jwt(claims) do
    headers = %{"alg" => "HS256"}

    jwk()
    |> JOSE.JWT.sign(headers, claims)
    |> JOSE.JWS.compact()
    |> elem(1)
  end

  def claims_from_jwt(jwt) do
    {true, %{fields: fields}, _} =
      JOSE.JWT.verify_strict(jwk(), ["HS256"], jwt)

    {:ok, fields}
  end

  defp jwk do
    passphrase = Application.fetch_env!(:not_skull, :secret_passphrase)

    passphrase
    |> Base.decode64!()
    |> JOSE.JWK.from_oct()
  end
end
