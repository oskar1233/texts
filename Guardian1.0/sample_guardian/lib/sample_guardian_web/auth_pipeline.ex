defmodule SampleGuardianWeb.AuthPipeline do

  use Guardian.Plug.Pipeline, otp_app: :sample_guardian,
    module: SampleGuardianWeb.Guradian,
    error_handler: SampleGuardianWeb.AuthErrorHandler

  plug Guardian.Plug.VerifyHeader, claims: %{"typ" => "access"}, realm: :none
  plug Guardian.Plug.EnsureAuthenticated
  plug Guardian.Plug.LoadResource, ensure: true

end
