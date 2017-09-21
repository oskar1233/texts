defmodule SampleGuardianWeb.AuthErrorHandlerTest do
  use SampleGuardianWeb.ConnCase

  alias SampleGuardianWeb.AuthErrorHandler

  describe("#auth_error") do

    test "sends 401 resp with {message: <type>} json as body", %{conn: conn} do
      conn = AuthErrorHandler.auth_error(conn, {:unauthorized, nil}, nil)

      assert conn.status == 401
      assert conn.resp_body == Poison.encode!(%{message: "unauthorized"})
    end

  end

end
