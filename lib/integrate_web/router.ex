defmodule IntegrateWeb.Router do
  use IntegrateWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
    plug IntegrateWeb.AuthPlug
  end

  pipeline :authenticated do
    plug IntegrateWeb.AuthRequiredPlug
  end

  pipeline :authenticated_unless_creating_root_user do
    plug IntegrateWeb.AuthRequiredUnlessNoUsersPlug
  end

  scope "/api", IntegrateWeb do
    pipe_through :api

    scope "/v1" do
      scope "/auth" do
        post "/login", AuthController, :login
        post "/renew", AuthController, :renew
      end

      scope "/" do
        pipe_through :authenticated

        resources "/users", UserController, except: [:new, :create, :edit]

        scope "/stakeholders" do
          resources "/", StakeholderController, except: [:new, :edit]

          get "/:id/:type", SpecificationController, :show
          put "/:id/:type", SpecificationController, :update
        end
      end

      scope "/" do
        pipe_through :authenticated_unless_creating_root_user

        post "/users", UserController, :create
      end
    end
  end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through [:fetch_session, :protect_from_forgery]
      live_dashboard "/dashboard", metrics: IntegrateWeb.Telemetry
    end
  end
end
