defmodule SampleGuardianWeb.Router do
  use SampleGuardianWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", SampleGuardianWeb do
    pipe_through :api

    resources "/users", UserController, except: [:new, :edit]
  end
end
