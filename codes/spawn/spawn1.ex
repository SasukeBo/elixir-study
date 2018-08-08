defmodule Spawn1 do
  def greet do
    receive do
      {sender, msg} ->
        send sender, {:ok, "Hello, #{msg}"}
    end
  end
end

defmodule SM do
  # send message
  def send_message(msg) do
    pid = spawn(Spawn1, :greet, [])
    send pid, {self(), "#{msg}"}
  end
end

defmodule RM do
  # receive message
  def receive_message do
    receive do
     {:ok, message} ->
       IO.puts message
    after 500 -> # 在等待500ms后没有消息进入则停止等待。
      IO.puts "消息队列为空，没有需要接收的消息！"
    end
  end
end

