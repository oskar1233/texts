# Guardian 1.0

I have recently started a new project in Elixir/Phoenix and noticed new Guardian version - 1.0 (in beta at the time I'm writing this post). I couldn't wait to try new, more consistent API of this wonderful authentication library. My integration is done and I decided to write a short tutorial for people starting with Guardian who don't want to dig into documentation too deep.

If you want to understand all the stuff described here, visit [docs](https://hexdocs.pm/guardian/1.0.0-beta.0/) or at least read the [project's github page (readme)](https://github.com/ueberauth/guardian).

# Creating a new project

I'll be using the newer (1.3.0) version of Phoenix here and test the application using ExUnit. Command for creating new project looks like this:

``` bash
mix phx.new sample_guardian --no-brunch --no-html
```

as we don't need no brunch/html stuff.

Use `config/test.exs` and `config/dev.exs` to configure your database depending on your needs. I am using Postgres so the default configuration works for me.

Now, we will need to add Guardian as a dependency. We open up our mix.exs file and add `{:guardian, "~> 1.0-beta"}` to our `deps` so they look similar to this:

``` elixir
[
  {:phoenix, "~> 1.3.0"},
  {:phoenix_pubsub, "~> 1.0"},
  {:phoenix_ecto, "~> 3.2"},
  {:postgrex, ">= 0.0.0"},
  {:gettext, "~> 0.11"},
  {:cowboy, "~> 1.0"},

  {:guardian, "~> 1.0-beta"}
]
```

Now let's run `mix deps.get` and we are ready to go.

# Users

Let's create a simple `User` scaffold using the Phoenix's json generator:

``` bash
mix phx.gen.json Users User users email:stirng password:string is_admin:boolean
```

I will not cover password hashing here - plain text will work *just for example*. 

Add an entry for users in `lib/sample_guardian_web/router.ex`:

``` elixir
scope "/api", SampleGuardianWeb do
  pipe_through :api
  
  resources "/users", UserController, except: [:new, :edit]
end
```

Let's run `mix test` and see what is going on

```
17 tests, 0 failures
```

All the default test should pass. Let's move on and make something fail.

# Guradian module

New version of Guradian uses different approach to using it then the previous versions. We should use `Guardian` behaviour in one of our modules. It will implement:
- encoding resource for token using `subject_for_token (resource, claims)`
- decoding resource from claims using `resource_from_claims (claims)`.

## `subject_for_token`

First parameter of our `subject_for_token` will be always `User` struct, because we don't have any other resource to encode in our token. For any other argument provided we will return `unknown_resource` error.

The encoded user will be a string in format `User:<id>`.

The second parameter are current claims. We don't really need it in our example.

Let's write some test. Open `test/sample_guardian_web/guardian_test.exs`.

``` elixir
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

  def create_user(_params) do
    {:ok, user} = Users.create_user(@user_attrs)
    {:ok, user: user}
  end

end

```

`create_user` method helps us to inject user in params for our test.

Let's see how `mix test` fails and now we can implement `subject_for_token`. Open up `lib/sample_guardian_web/guardian.ex`.

``` elixir
defmodule SampleGuardianWeb.Guardian do
  use Guardian, otp_app: :sample_guardian

  alias SampleGuardian.Users.User

  def subject_for_token(user = %User{}, _claims) do
    {:ok, "User:" <> to_string(user.id)}
  end

  def subject_for_token(_, _) do
    {:error, :unknown_resource}
  end

end
```

`subject_for_token` when %User{} given encodes it to "User:#{id}" string. When no other prototypes match, `{:error, :unknown_resource}` is returned. Pretty straightforward. `mix test` should pass now.

## `resource_from_claims`

This function receives `claims` map as a parameter. Our encoded resource is stored in `sub` key of this map, so we care only about it.

`sub`'s format for our application should always match `User:<id>` pattern. Moreover, our `User.id` is integer, so we test the methods behaviour for:
- invalid id provided (e.g. `User:123ace`) - should return `invalid_id` error
- invalid `sub` provided (e.g. `SampleNoun:123`) - should return `invalid_claims` error
- id of non-existing record provided - should return `no_result` error

...and for valid claims with valid, existing id given it should return `User` matching to our id.

Let's add some test for the second method of `Guardian` behaviour.

``` elixir
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

```

`mix test` shoud fail, so let's now implement the method in `SampleGuardianWeb.Guardian` module.

``` elixir
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

```

In the function we parse the `sub` key and return user fetched from repo.

We also rescue `Ecto.NoResultsError` so we can return proper error message (`:no_result` when error raised).

That's pretty much working Guardian module.

# Auth error handler

Next thing we need to create is auth error handler. We need to implement only one function in it: `auth_error`. As arguments it receives connection, error `{type, reason}` tuple and options. We'll simply encode error's type to json and send it in response alongside with 401 http code.

Let's write some tests in `test/sample_guardian_web/auth_error_handler_test.exs`.

``` elixir
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

```

The test will obviously fail. Let's create the auth error module in `lib/sample_guardian_web/auth_error_handler.ex`.

``` elixir
defmodule SampleGuardianWeb.AuthErrorHandler do
  import Plug.Conn

  def auth_error(conn, {type, reason}, _opts) do
    body = Poison.encode!(%{message: to_string(type)})
    send_resp(conn, 401, body)
  end
end

```

Again, pretty straightforward: in `auth_error` method we encode `%{message: type}` map to JSON using poison and send response with 401 http code.

# Pipelines

Guardian 1.0 introduces new concept based on pipelines. Pipeline is a helper module used for collecting together plugs used for a particular authentication scheme. We can create one by using `Guardian.Plug.Pipeline`. Here is a sample of guardian pipeline made for API access (verifies only headers, not session): it ensures that the token exists in `Authorization` header and ensures that resource which it points to exists.

``` elixir
defmodule SampleGuardianWeb.AuthPipeline do

  use Guardian.Plug.Pipeline, otp_app: :sample_guardian,
    module: SampleGuardianWeb.Guradian,
    error_handler: SampleGuardianWeb.AuthErrorHandler

  plug Guardian.Plug.VerifyHeader, claims: %{"typ" => "access"}, realm: :none
  plug Guardian.Plug.EnsureAuthenticated
  plug Guardian.Plug.LoadResource, ensure: true

end

```

Now, we can use it for example in our `UserController` like this: `plug Coinwiz.AuthPipeline`. It will ensure that only authenticated uses have access to `UserController`.

# Permissions

What if only admin can see one of our controllers? We need some kind of permissions system. But we don't want to check the database everytime admin makes a request. We want the permissions to be stateless on the server side. Let's encode them to our token!

Guardian provided such system for us. It is similar to OAuth permissions in some sense - we need to tell what kind of permissions do we want to allow, for example `admin: [:moderate, :super], user: [:invoices, :companies]`. Guardian's permissions can have one level of nesting.

We declare all possible permissions for our application (or for one guardian behaviour) in guardian module:

``` elixir
defmodule SampleGuardianWeb.Guardian do
  use Guardian, otp_app: :sample_guardian,
    permissions: %{
      superuser: [:moderate, :super],
      user: [:invoices, :companies]
    }
```

Then we need to create new function in the same module to build claims which we are encoding including permissoins. It can look like this:

``` elixir
def build_claims(claims, _resource, opts) do
  claims = claims
           |> encode_permissions_into_claims!(Keyword.get(opts, :permissions))
  {:ok, claims}
end
```

Now, when we use `encode_and_sign` method, we can specify permissions to encode like this: `{:ok, token, _claims} = Coinwiz.Guardian.encode_and_sign(user, %{}, permissions: %{user: [:invoices]})`. Then in our invoices controller we can write:

``` elixir
plug SampleGuardianWeb.AuthPipeline

# Only user with invoices permission can have access here
plug Guardian.Permissions.Bitwise, ensure: %{user: [:invoices]}

# Only admin can remove invoices
plug Guardian.Permissions.Bitwise, [ensure: %{user: [:invoices]}] when action in [:delete]
```

In the sample project you can see most of code used here - it is not working example, but can be used as a base for using new Guardian 1.0.

Thanks for reading!
