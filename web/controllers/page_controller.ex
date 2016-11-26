defmodule PassTheChain.PageController do
  use PassTheChain.Web, :controller

  alias PassTheChain.UsernamesRegistry

  require Logger

  # GET /
  def index(conn, _params) do
    if conn.assigns.username do
      render(conn, "index.html")
    else
      render(conn, "login.html")
    end
  end

  # POST /login
  def login(conn, %{"login_params" => %{"username" => username}}) do
    if byte_size(username) > 0 do
      case UsernamesRegistry.put_new(username) do
        :ok ->
          redirect_path = get_session(conn, :redirect_to_after_login) || page_path(conn, :index)
          conn
          |> put_session(:redirect_to_after_login, nil)
          |> put_session(:username, username)
          |> redirect(to: redirect_path)
        {:error, :already_present} ->
          conn
          |> put_flash(:error, "Username \"#{username}\" is already present")
          |> redirect_to_homepage()
      end
    else
      conn
      |> put_flash(:error, "Username must not be empty")
      |> redirect_to_homepage()
    end
  end

  # POST /logout
  def logout(conn, %{}) do
    UsernamesRegistry.delete(conn.assigns.username)

    conn
    |> put_session(:username, nil)
    |> put_flash(:info, "Logged out")
    |> redirect_to_homepage()
  end

  defp redirect_to_homepage(conn) do
    redirect(conn, to: page_path(conn, :index))
  end
end
