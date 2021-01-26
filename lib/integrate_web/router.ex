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
end
