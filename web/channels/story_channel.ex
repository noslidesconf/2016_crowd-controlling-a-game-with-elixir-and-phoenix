defmodule PassTheChain.StoryChannel do
  use Phoenix.Channel

  alias PassTheChain.{Presence, Story}

  require Logger

  def join("story:" <> story_slug, %{} = _params, socket) do
    Logger.debug "User \"#{socket.assigns.username}\" joined story \"#{story_slug}\""
    send(self(), :after_join)
    {:ok, assign(socket, :story_slug, story_slug)}
  end

  def handle_in("new_word", %{"new_word" => word, "author" => author}, socket) do
    word = Story.append_word(socket.assigns.story_slug, word, author)
    broadcast!(socket, "appended_word", %{"appended_word" => word})
    {:noreply, socket}
  end

  def handle_info(:after_join, socket) do
    Presence.track(socket, socket.assigns.username, %{})

    :ok = Story.maybe_activate(socket.assigns.story_slug)

    push(socket, "after_join", %{
      presence_state: Presence.list(socket),
      story: Story.get_info_if_exists(socket.assigns.story_slug),
    })

    {:noreply, socket}
  end
end
