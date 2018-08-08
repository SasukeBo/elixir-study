# GenServer behaviour

处理服务器客户端关系

一个GenServer进程就如一般的Elixir进程一样，可以保持自身状态，异步执行代码等。

使用这个模块来实现服务的好处在于，会拥有一套标准的接口方法，跟踪以及错误报告。

且适用于进程管理树（Supervisor）。

## Example

和Supervisor文档中用到的例子一样，使用GenServer实现一个栈服务。代码如下：

```elixir
defmodule Stack do
  use GenServer

  @impl true
  def init(stack) do
    {:ok, stack}
  end

  @impl true
  def handle_call(:pop, _from, [head | tail]) do
    {:reply, head, tail}
  end

  @impl true
  def handle_cast({:push, item}, state) do
    {:noreply, [item | state]}
  end
end
```

在iex中可以测试一下效果

```elixir
# Start the server
{:ok, pid} = GenServer.start_link(Stack, [:hello])

# This is the client
GenServer.call(pid, :pop)
#=> :hello

GenServer.cast(pid, {:push, :world})
#=> :ok

GenServer.call(pid, :pop)
#=> :world
```

## Client/Server APIs

上面在iex中直接使用GenServer模块的call、cast方法来和服务通信的方式是很不友好的。

我们需要封装这些方法，作为客户端的接口来使用。

例如：

```elixir
defmodule Stack do

  ...
  # Client APIs

  # 用于启动Stack服务
  def start_link(default) when is_list(default) do
    GenServer.start_link(__MODULE__, default)
  end

  def push(item) do
    GenServer.cast(Stack, {:push, item})
  end

  def pop do
    GenServer.call(Stack, :pop)
  end

  ...
end
```

练习中我们可以将服务端方法和客户端方法写在一个模块中，

但如果服务端或客户端的业务逻辑越来越复杂，将它们拆分到不同的模块是个好的选择。

## use GenServer and callbacks

GenServer有7个回调函数可以被实现。其中`init/1`方法是必须的。

`use GenServer`会定义`child_spec/1`方法，这样使得模块可以被添加到Supervisor中。

生成child_spec方法时可以指定一些自定义设置：

* `:id` 子进程配置名，默认是当前模块名。
* `:start` 指定启动子进程的方法，默认是`__MODULE__.start_link/1`
* `:restart` 指定子进程重启策略，默认是`:permanent`(任何情况下停止都会被重启)
* `shutdown` 指定关闭子进程最大时间。单位毫秒，`:infinity`表示不限制进程关闭时间，父进程等待直到子进程关闭。

For Example:
```elixir
use GenServer, restart: :transient, shutdown: 10_000
```

## Name registration

GenServer的`start_link/3`和`start/3`方法都支持通过`:name`注册进程名字。

这个注册名在进程终止时会被自动清除。

## Receiving "regular" messages

GenServer的目的在于抽象接收流程，自动处理系统消息，支持代码变化、同步调用等功能。

因此，我们不应该在GenServer的回调函数中使用我们自定义的接收流程。

## When (not) to use a GenServer


