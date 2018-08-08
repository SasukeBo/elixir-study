defmodule Link2 do
  import :timer, only: [sleep: 1]

  def sad_function do
    sleep 500
    exit(:boom)
  end

  def run do
    # Process.flag(:trap_exit, true)
    res = spawn_monitor(Link2, :sad_function, [])
    # spawn_link(Link2, :sad_function, [])
    IO.puts inspect res
    receive do
      msg ->
        IO.puts "MESSAGE RECEIVE: #{inspect msg}"
    after 1000 ->
      IO.puts "Nothing happened as far as I am concerned"
    end
  end
end

# 子进程非正常退出会结束整个应用，这是关联进程的默认行为。
