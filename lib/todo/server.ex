defmodule Todo.Server do
  use GenServer, restart: :temporary

  def start_link(todo_list_name) do
    IO.puts("Starting to-do server for #{todo_list_name}")
    GenServer.start_link(__MODULE__, todo_list_name, name: via_tuple(todo_list_name))
  end

  def add_entry(todo_server, new_entry) do
    GenServer.cast(todo_server, {:add_entry, new_entry})
  end

  def update_entry(todo_server, new_entry) do
    GenServer.cast(todo_server, {:update_entry, new_entry})
  end

  def entries(todo_server, date) do
    GenServer.call(todo_server, {:entries, date})
  end

  def delete_entry(todo_server, entry) do
    GenServer.call(todo_server, {:delete_entry, entry})
  end

  defp via_tuple(name) do
    Todo.ProcessRegistry.via_tuple({__MODULE__, name})
  end

  @impl GenServer
  def init(todo_list_name) do
    {:ok, {todo_list_name, Todo.Database.get(todo_list_name) || Todo.List.new()}}
  end

  @impl GenServer
  def handle_call({:entries, date}, _, {name, todo_list}) do
    {
      :reply,
      Todo.List.entries(todo_list, date),
      {name, todo_list}
    }
  end

  @impl GenServer
  def handle_cast({:add_entry, entry}, {name, todo_list}) do
    new_list = Todo.List.add_entry(todo_list, entry)
    Todo.Database.store(name, new_list)
    { :noreply, {name, new_list} }
  end

  @impl GenServer
  def handle_cast({:update_entry, entry}, {name, todo_list}) do
    new_list = Todo.List.update_entry(todo_list, entry)
    Todo.Database.store(name, new_list)
    { :noreply, {name, new_list} }
  end

  @impl GenServer
  def handle_cast({:delete_entry, entry}, {name, todo_list}) do
    new_list = Todo.List.delete_entry(todo_list, entry)
    Todo.Database.store(name, new_list)
    {:noreply, {name, new_list}}
  end
end
