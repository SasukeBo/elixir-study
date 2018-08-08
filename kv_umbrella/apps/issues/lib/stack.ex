defmodule Stack do
  use GenServer

  def start_link(state) do
    IO.inspect "go through start_link/1"
    IO.inspect state
    state = [:sasuke]
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  @impl true
  def init(stack) do
    IO.inspect "go through init/1"
    IO.inspect stack
    {:ok, stack}
  end

  def pop() do
    GenServer.call(Stack, :pop)
  end

  def push(attr) do
    GenServer.cast(Stack, {:push, attr})
  end

  @impl true
  def handle_call(:pop, _from, [head | tail]) do
    {:reply, head, tail}
  end

  @impl true
  def handle_cast({:push, head}, tail) do
    {:noreply, [head | tail]}
  end
end
