defmodule PassTheChain.StoryController do
  use PassTheChain.Web, :controller

  alias PassTheChain.Story

  def create(conn, %{"story" => %{"title" => story_title}}) do
    slug = Slugger.slugify_downcase(story_title)

    case Story.start(slug, story_title, conn.assigns[:username]) do
      :ok ->
        redirect(conn, to: story_path(conn, :show, slug))
      {:error, :already_started} ->
        conn
        |> put_flash(:error, "Story with this title already exists")
        |> redirect(to: page_path(conn, :index))
    end
  end

  def show(conn, %{"story_slug" => story_slug}) do
    if story_info = Story.get_info_if_exists(story_slug) do
      render(conn, "show.html", story: story_info)
    else
      conn
      |> put_flash(:error, "That didn't look like an existing story")
      |> redirect(to: page_path(conn, :index))
    end
  end
end
