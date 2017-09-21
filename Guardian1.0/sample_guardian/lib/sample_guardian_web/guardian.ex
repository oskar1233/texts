defmodule SampleGuardianWeb.Guardian do
  use Guardian, otp_app: :sample_guardian,
    permissions: %{
      superuser: [:moderate, :super],
      user: [:invoices, :companies]
    }

  alias SampleGuardian.Users
  alias SampleGuardian.Users.User

  def subject_for_token(user = %User{}, _claims) do
    {:ok, "User:" <> to_string(user.id)}
  end

  def subject_for_token(_, _) do
    {:error, :unknown_resource}
  end

  def resource_from_claims(%{"sub" => "User:" <> uid_str}) do
    try do
      case Integer.parse(uid_str) do
        {uid, ""} ->
          {:ok, Users.get_user!(uid)}
        _ ->
          {:error, :invalid_id}
      end
      rescue
        Ecto.NoResultsError -> {:error, :no_result}
    end
  end

  def resource_from_claims(_) do
    {:error, :invalid_claims}
  end

  def build_claims(claims, _resource, opts) do
    claims = claims
             |> encode_permissions_into_claims!(Keyword.get(opts, :permissions))
    {:ok, claims}
  end

end
