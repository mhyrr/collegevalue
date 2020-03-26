defmodule CollegevalueWeb.Router do
  use CollegevalueWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug Phoenix.LiveView.Flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", CollegevalueWeb do
    pipe_through :browser

    get "/", PageController, :index

    resources "/colleges", CollegeController, except: [:edit, :delete]

    live "/fields", FieldsLive.Index
    live "/fields/:name", FieldsLive.Show

    get "/top", RankController, :index

    # get "/fields/:name", FieldController, :show

  end

  # Other scopes may use custom stacks.
  # scope "/api", CollegevalueWeb do
  #   pipe_through :api
  # end
end
