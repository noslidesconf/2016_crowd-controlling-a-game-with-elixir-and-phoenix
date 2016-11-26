defmodule PassTheChain.Story do
  use GenServer

  alias PassTheChain.{Endpoint, Presence}

  require Logger

  @timeout 8000

  defstruct [
    :slug,
    :title,
    :creator,
    :elected_writer,
    active?: false,
    words: [],
  ]

  defmodule Word do
    @enforce_keys [:word, :author]
    defstruct @enforce_keys
  end

  ## Public API

  def start(slug, title, creator)
      when is_binary(slug) and is_binary(title) and is_binary(creator) do
    state = %__MODULE__{
      slug: slug,
      title: title,
      creator: creator,
    }

    case GenServer.start(__MODULE__, state, name: via(slug)) do
      {:ok, _pid} ->
        :ok
      {:error, {:already_started, _}} ->
        {:error, :already_started}
    end
  end

  def append_word(slug, word, author)
      when is_binary(slug) and is_binary(word) and is_binary(author) do
    GenServer.call(via(slug), {:append_word, %Word{word: word, author: author}})
  end

  def get_info_if_exists(slug) when is_binary(slug) do
    try do
      GenServer.call(via(slug), :get_info)
    catch
      :exit, {:noproc, {_, _, _}} ->
        nil
    end
  end

  def maybe_activate(slug) when is_binary(slug) do
    GenServer.cast(via(slug), :maybe_activate)
  end

  ## GenServer callbacks

  def init(%__MODULE__{} = state) do
    {:ok, state}
  end

  def handle_call({:append_word, %Word{} = word}, _from, state) do
    {:reply, word, %{state | words: state.words ++ [word]}}
  end

  def handle_call(:get_info, _from, state) do
    {:reply, Map.take(state, [:slug, :title, :creator, :words, :elected_writer]), state}
  end

  def handle_cast(:maybe_activate, state) do
    state =
      if state.active? do
        state
      else
        send(self(), :elect_next_writer)
        %{state | active?: true}
      end

    {:noreply, state}
  end

  def handle_info(:elect_next_writer, state) do
    state =
      case Map.keys(Presence.list(topic(state))) do
        [] ->
          Logger.debug("No participants in this story so no elected writer")
          state
        participants ->
          broadcast_next_writer_election(state, Enum.random(participants), state.elected_writer)
      end

    Process.send_after(self(), :elect_next_writer, @timeout)

    {:noreply, state}
  end

  ## Helpers

  defp via(slug) do
    {:via, Registry, {PassTheChain.StoriesRegistry, slug}}
  end

  defp topic(state) do
    "story:#{state.slug}"
  end

  defp broadcast_next_writer_election(state, elected, previous) do
    Logger.debug "Broadcasting the election of the next writer: #{inspect(elected)}"

    Endpoint.broadcast!(topic(state), "elected_next_writer", %{
      "elected" => elected,
      "previous" => previous,
    })

    %{state | elected_writer: elected}
  end
end
