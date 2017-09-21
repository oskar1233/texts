defmodule SampleGuardianWeb.GuardianTest do
  use SampleGuardian.DataCase

  alias SampleGuardian.Users

  alias SampleGuardianWeb.Guardian
  
  @user_attrs %{email: "mail@example.org", password: "Pwd123", is_admin: false}

  describe("#subject_for_token for %User{} given") do
    setup :create_user

    test "returns User:<id>", %{user: user} do
      assert Guardian.subject_for_token(user, nil) == {:ok, "User:#{user.id}"}
    end
  end

  describe("#subject_for_token for unknown resource given") do

    test "returns error" do
      assert Guardian.subject_for_token(%{some: "thing"}, nil) == {:error, :unknown_resource}
    end

  end

  describe("#resource_from_claims for 'User:<valid_id>' given") do
    setup :create_user

    test "returns {:ok, %User{}} tuple", %{user: user} do
      assert Guardian.resource_from_claims(%{"sub" => "User:" <> to_string(user.id) }) == {:ok, user}
    end

  end

  describe("#resource_from_claims for 'User:<invalid_id>' given") do

    test "returns {:error, :invalid_id} tuple" do
      assert Guardian.resource_from_claims(%{"sub" => "User:a9sd9"}) == {:error, :invalid_id}
      assert Guardian.resource_from_claims(%{"sub" => "User:123ace"}) == {:error, :invalid_id}
      assert Guardian.resource_from_claims(%{"sub" => "User:"}) == {:error, :invalid_id}
    end

  end

  describe("#resource_from_claims for 'User:<non_existing>' given") do

    test "returns {:error, :no_result} tuple" do
      assert Guardian.resource_from_claims(%{"sub" => "User:99999"}) == {:error, :no_result}
    end

  end

  describe("#resource_from_claims for other string given") do

    test "returns {:error, :invalid_claims} tuple" do
      assert Guardian.resource_from_claims(%{"sub" => "SampleNoun:123"}) == {:error, :invalid_claims}
    end

  end

  def create_user(_params) do
    {:ok, user} = Users.create_user(@user_attrs)
    {:ok, user: user}
  end

end
