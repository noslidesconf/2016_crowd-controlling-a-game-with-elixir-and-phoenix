defmodule PassTheChain.UsernamesRegistry do
  use GenServer

  defstruct usernames: MapSet.new

  def start_link() do
    GenServer.start_link(__MODULE__, %__MODULE__{}, name: __MODULE__)
  end

  def put_new(username) when is_binary(username) do
    GenServer.call(__MODULE__, {:put_new, username})
  end

  def delete(username) when is_binary(username) do
    GenServer.call(__MODULE__, {:delete, username})
  end

  ## GenServer callbacks

  def handle_call({:put_new, username}, _from, state) do
    if MapSet.member?(state.usernames, username) do
      {:reply, {:error, :already_present}, state}
    else
      {:reply, :ok, %{state | usernames: MapSet.put(state.usernames, username)}}
    end
  end

  def handle_call({:delete, username}, _from, state) do
    {:reply, :ok, %{state | usernames: MapSet.delete(state.usernames, username)}}
  end
end
