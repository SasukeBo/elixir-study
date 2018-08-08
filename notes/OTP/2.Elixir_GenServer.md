# GenServer

因为agents是进程，所以每一个bucket会有个进程ID，但是它们都没有名字。

我们可以用atom给进程注册一个名字：

```sh
iex> Agent,start_link(fn -> %{} end, name: :shopping)
{:ok, #PID<0.43.0>}
iex> KV.Bucket.put(:shopping, "milk", 1)
:ok
iex> KV.Bucket.get(:shopping, "milk")
1
```

但是用atom给进程注册名字是一件可怕的事情，因为atom是不可回收的，
创建后就常驻内存，所以大量用户输入命名会耗尽内存。

所以我们可以选择创建一个registry进程用于注册bucket的名字，实际上就是将name和PID关联起来。

这个registry进程需要确保PID和name关联信息一直是最新的。
例如一个bucket进程崩溃后，registry进程需要立刻做出反应，也就是registry需要监控buckets。

下面我们用GenServe来创建一个registry进程，用于监控bucket进程。

## Our first GenServer

一个GenServer的实现应该包含两部分：客户端API和服务端回调函数。

你可以把两部分组织在一个模块，也可以分开。

这两部分完全运行在不同的进程中。

这里我们在一个模块中实现两部分：

```elixir
defmodule KV.Registry do
  use GenServer

  ## Client API

  @doc """
  Starts the registry.
  """
  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  @doc """
  Looks up the bucket pid for `name` stored in `server`.

  Returns `{:ok, pid}` if the bucket exists, `:error` otherwise.
  """
  def lookup(server, name) do
    GenServer.call(server, {:lookup, name})
  end

  @doc """
  Ensures there is a bucket associated with the given `name` in `server`.
  """
  def create(server, name) do
    GenServer.cast(server, {:create, name})
  end

  ## Server Callbacks

  def init(:ok) do
    {:ok, %{}}
  end

  def handle_call({:lookup, name], _from, names}) do
    {:reply, Map.fetch(names, name), names}
  end

  def handle_cast({:create, name}, names) do
    if Map.has_key?(names, name) do
      {:noreply, names}
    else
      {:ok, bucket} = KV.Bucket.start_link([])
      {noreply, Map.put(names, name, bucket)}
    end
  end
end
```

第一个函数时start_link，启动一个GenServer进程。有三个参数：
* 实现了GenServer回调函数的模块名`__MODULE__`；
* 初始化参数，这里是:ok，它会被传递给回调函数init/1；
* 由启动进程配置选项组成的列表，默认为空列表。



发送给服务端的请求有两种类型：calls和casts。

其中calls是同步执行，服务端必须返回请求响应。

casts是异步执行的，服务端不需要回复请求。



`lookup/2`和`create/2`的作用是发送请求给服务端。请求内容一般是元组，

如上面例子中分别传递的是{:lookup, name}和{:create, name}。

一般元组的第一个参数是指定服务端action，后面的参数是真正需要处理的数据。



client大概就是这样，而server端可以实现多种回调函数确保能够处理server的初始化、

终止以及处理各种请求。当然这些回调函数并不全是必须要实现的。



第一个回调函数是`init/1`，GenServer.start_link函数的第二个参数会传递给init函数。

返回{:ok, state}，本例中state是一个空map。


对应`call/2`请求，实现`handle_call/3`回调函数来接收请求。
`form`参数表示请求发出者，`names`服务端当前的状态，
这个回调函数返回`{:reply, reply, new_state}`格式的响应，`reply`是发送给客户端的数据，
`new_state`是服务器的新状态。

对应`cast/2`请求，实现`handle_cast/2`回调函数来接收请求。返回格式为`{:noreply, new_state}`，
需要注意的是，实际项目中我们需要使用同步回调函数`call`来处理:create，因为cast是异步回调函数，
不会返回给客户端请求响应，而create一个进程是需要反馈信息的。

本例中这么做的目的是举例说明如何实现一个cast回调函数。

还有其他几种回调函数和请求响应格式在[文档](https://hexdocs.pm/elixir/GenServer.html)中有详细说明。


## Testing a GenServer

```elixir
defmodule KV.RegistryTest do
  use ExUnit.Case, async: true

  setup do
    registry = start_supervised!(KV.Registry)
    %{registry: registry}
  end

  test "spawns buckets", %{registry: registry} do
    assert KV.Registry.lookup(registry, "shopping") == :error

    KV.Registry.create(registry, "shopping")
    assert {:ok, bucket} = KV.Registry.lookup(registry, "shopping")

    KV.Bucket.put(bucket, "milk", 1)
    assert KV.Bucket.get(bucket, "milk") == 1
  end
end
```

比较这里的setup和bucket_test中的setup，没有使用start_link函数来启动registry进程，
而是调用ExUnit的start_supervisor函数。

后者的好处在于会在下一段测试开始前自动终止当前测试启动的进程，
当进程共享资源时，可以保证上一段测试的状态不会影响到下一段测试的状态。

所以在测试中启动一个process时，最好使用start_supervisor!。

另外，如果需要停止一个GenServer，可以添加一个stop方法：

```elixir
  ## Client API

  @doc """
  Stops the registry.
  """
  def stop(server) do
    GenServer.stop(server)
  end
```

## The need for monitoring

接下来学习如何监控子进程。先写一段测试：

```elixir
  test "removes buckets on exit", %{registry: registry} do
    KV.Registry.create(registry, "shopping")
    {:ok, bucket} = KV.Registry.lookup(registry, "shopping")
    Agent.stop(bucket)
    assert KV.Registry.lookup(registry, "shopping") == :error
  end
```

在没有添加监控机制前，上面的测试会失败，因为当一个bucket进程停止时，
registry并不会更新其持有的name和PID的key-value 映射，如果我们调用lookup函数，
任然会返回这个映射，只不过获得的进程pid对应的进程已经dead。

一旦添加了监控机制，只要有bucket进程终止，监控机制就会发送进程消息给registry进程。
registry在收到这个消息时就可以及时更新name-PID的map。

```sh
iex> {:ok, pid} = KV.Bucket.start_link([])
{:ok, #PID<0.66.0>}
iex> Process.monitor(pid)
#Reference<0.0.0.551>
iex> Agent.stop(pid)
:ok
iex> flush()
{:DOWN, #Reference<0.0.0.551>, :process, #PID<0.66.0>, :normal}
```

`Process.monitor(pid)`会返回唯一的标识，可以用来匹配接收到的进程消息，
从而定位到是哪个进程退出了。

`flush/0`函数可以弹出当前进程收到的所有进程消息。

接下里重新实现以下这些回调函数：

首先需要调整GenServer的状态为两个map，一个用于存储name和PID的映射，
另一个用于存储监控标识（Reference）和name的映射。

然后我们需要在create bucket的时候及时添加监控机制，也就是handle_cast函数中的处理过程。

下面是完整的服务端回调函数：

```elixir
  ## Server Callbacks

  def init(:ok) do
    names = %{}
    refs = %{}
    {:ok, {names, refs}}
  end

  def handle_call({:lookup, name}, _from, {names, _} = state) do
    # handle_call 需要回复信息，而tuple的第二个元素就是回复信息，
    # 用于返回给client。第三个元素用来更新服务器状态（states）
    {:reply, Map.fetch(names, name), state}
  end

  def handle_cast({:create, name}, {names, refs}) do
    # handle_cast 不需要返回回复信息，所以tuple的第二个元素
    # 是用来更新服务端状态（states）的
    if Map.has_key?(names, name) do
      {:noreply, {names, refs}}
    else
      {:ok, pid} = KV.Bucket.start_link([name: name])
      ref = Process.monitor(pid)
      refs = Map.put(refs, ref, name)
      names = Map.put(names, name, pid)
      {:noreply, {names, refs}}
    end
  end

  @doc """
  这个回调函数会处理所有发送给Registry进程的信息，例如:

  ## Example

      iex> {:ok, pid} = KV.Registry.start_link([])
      iex> send(pid, {:DOWN, "123", :process, "", ""})
      "123"

  如果在里面打印ref，会发现就是"123"
  """
  def handle_info({:DOWN, ref, :process, _pid, _reason}, {names, refs}) do
    IO.inspect ref
    {name, refs} = Map.pop(refs, ref)
    names = Map.delete(names, name)
    {:noreply, {names, refs}}
  end

  def handle_info(_msg, state) do
    {:noreply, state}
  end
```

回过头来发现修改服务端回调函数没有影响到客户端API的工作，这也是C/S分隔的好处。

最后还定义了一个handle_info(_msg, state)用于匹配任何其它未知的消息。

## Call、Cast or Info?

目前为止我们用到了除init之外的三个回调函数：`handle_call/3`, `handle_cast/2`和`handle_info/2`。

下面对每个回调函数使用场合简单说明：

* `handle_call/3`被用于同步请求，当需要服务端返回请求响应时，需要使用这个回调函数。
* `handle_cast/2`被用于异步请求，当你不在乎服务端对请求的处理结果时可以使用这个回调函数。
* `handle_info/2`所有不是`GenServer.call/2`和`GenServer.cast/2`函数发送的请求，
都用`handle_info/2`来接收。


由于有很多途径发送进程消息，所以有必要定义一个匹配所有消息的函数体，否则会造成registry的崩溃。

## Monitors or Links?

什么场景下适合使用monitor和link？

如果希望一个进程的终止会造成另一个进程跟着终止，就需要使用link关联两个进程。
link的双方都可以感知对方进程的停止。
而monitor是单向的，只有检测者能知道被检测者的运行状态。

registry的例子中，link和monitor都用到了。

```elixir
  {:ok, pid} = KV.Bucket.start_link([])
  ref = Process.monitor(pid)
```

这种做法显然不是我们想要的，因为我们并不希望bucket的崩溃会造成整个registry的终止。
至此将引出强大的Supervisors。
