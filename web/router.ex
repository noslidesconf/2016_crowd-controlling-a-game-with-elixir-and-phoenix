defmodule PassTheChain.Router do
  use PassTheChain.Web, :router

  require Logger

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_username_from_session
  end

  pipeline :authenticated do
    plug :ensure_authenticated_or_redirect, redirect_to: "/"
  end

  scope "/", PassTheChain do
    pipe_through :browser # Use the default browser stack

    get "/", PageController, :index
    post "/login", PageController, :login
    post "/logout", PageController, :logout
  end

  scope "/stories", PassTheChain do
    pipe_through :browser
    pipe_through :authenticated

    get "/:story_slug", StoryController, :show
    post "/", StoryController, :create
  end

  defp fetch_username_from_session(conn, _opts) do
    assign(conn, :username, get_session(conn, :username))
  end

  defp ensure_authenticated_or_redirect(conn, opts) do
    if conn.assigns.username do
      conn
    else
      redirect_to = Keyword.fetch!(opts, :redirect_to)
      Logger.debug "User not logged in, redirecting them to #{redirect_to}"
      conn
      |> put_session(:redirect_to_after_login, conn.request_path)
      |> Phoenix.Controller.put_flash(:error, "You need to be logged in")
      |> Phoenix.Controller.redirect(to: redirect_to)
    end
  end
end
