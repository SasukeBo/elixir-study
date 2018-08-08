# The Trouble With State

Elixir是不可变语言，一般情况下不会共享数据。如果我们想提供一个容器，
可以在任何地方对这个容器进行读写操作，可以有两种选择：

* Elixir的进程（Process）
* ETS（Erlang Term Storage）

这里我们学习使用Elixir的OTP来使用进程：

* Agent 简单的处理一些进程状态。
* GenServer 包裹进程状态，提供同步和异步的回调函数处理进程状态、一些其他功能。
* Task 异步处理运算，启动进程并在之后的某个时间查询进程执行结果。

# Agents

先在iex中看一个例子:

```sh
iex> {:ok, agent} = Agent.start_link(fn -> [] end)
{:ok, #PID<0.57.0>}
iex> Agent.update(agent, fn list -> ["eggs" | list] end)
:ok
iex> Agent.get(agent, fn list -> list end)
["eggs"]
iex> Agent.stop(agent)
:ok
```
如上代码的意义：
* 启动一个agent，保存了一个空列表。
* 更新了agent中保存的列表，添加了"eggs"元素。
* 获取agent中保存的列表。
* 最终停止了这个agent。

上例可见Agent的update和get方法第二个参数是一个function，agent将存储的list传递给这个function，
function处理完这个list再返回给agent或输出给调用者。

接下来我们试着用Agent来实现一个bucket，在实现之前先编写一段测试：

```elixir
defmodule KV.BucketTest do
  use ExUnit.Case, async: true

  test "stores values by key" do
    {:ok, bucket} = KV.Bucket.start_link([])
    assert KV.Bucket.get(bucket, "milk") == nil

    KV.Bucket.put(bucket, "milk", 3)
    assert KV.Bucket.get(bucket, "milk") == 3
  end
end
```

测试单元的:async使我们的代码在多核处理器上异步运行。
但是需要注意的是，这种选项不适用于多个测试去竞争一个资源的情况。

接下来完善KV.Bucket模块：

```elixir
defmodule KV.Bucket do
  use Agent

  @doc """
  Starts a new bucket.
  """
  def start_link(_opts) do
    Agent.start_link(fn -> %{} end)
  end

  @doc """
  Gets a value from the `bucket` by `key`.
  """
  def get(bucket, key) do
    Agent.get(bucket, &Map.get(&1, key))
  end

  @doc """
  Puts the `value` for the given `key` in the `bucket`.
  """
  def put(bucket, key, value) do
    Agent.update(bucket, &Map.put(&1, key, value))
  end
end
```

第一步就是使用use Agent，
start_link方法会启动agent，opts包含了一些启动设置，可以为空。

get 和 put方法操作agent中存储的map。

## Test setup with ExUnit callbacks

在继续为bucket增加特性之前，讨论一下测试单元的回调函数。

KV.Bucket的每一项测试都需要一个agent在运行当中，我们可以借助测试单元的setup宏来解决这个问题。

```elixir
defmodule KV.BucketTest do
  use ExUnit.Case, async: true

  setup do
    {:ok, bucket} = KV.Bucket.start_link([])
    %{bucket: bucket}
  end

  test "stores values by key", %{bucket: bucket} do
    assert KV.Bucket.get(bucket, "milk") == nil

    KV.Bucket.put(bucket, "milk", 3)
    assert KV.Bucket.get(bucket, "milk") == 3
  end
end
```

通过setup来启动一个agent，以元组的方式返回这个agent的pid，上例中为bucket。

接着在测试中通过test context来接收这个pid：

```elixir
test "stores values by key", %{bucket: bucket} do
  # `bucket` is now the bucket from the setup block
end
```

## Other agent actions

除了get和update agent的state，还可以通过get_and_update方法同时获取并更新agent state。
可以依靠这个方法来实现bucket的删除功能。

```elixir
  @doc """
  Delete `keys` from `bucket`.

  Returns the current value of `key`, if `key` exists.
  """
  def delete(bucket, key) do
    Agent.get_and_update(bucket, &Map.pop(&1, key))
  end
```

## Client/Server in agents

下面讨论agent中的Client和Server，先展开delete方法：

```elixir
  def delete(bucket, key) do
    Agent.get_and_update(bucket, fn dict ->
      Map.pop(dict, key)
    end)
  end
```

匿名函数中的所有处理都是在agent进程中执行的。
这种情况下，agent接收并且回复消息的行为可以被视作Server行为。
而所有agent进程之外发生的事情都是客户端行为。

这个区分十分重要，如果有一个消耗非常大的运算需要执行，
就要考虑这个运算是在客户端处理还是服务器端处理比较合适。例如：

```elixir
def delete(bucket, key) do
  Process.sleep(1000) # puts client to sleep
  Agent.get_and_update(bucket, fn dict ->
    Process.sleep(1000) # puts server to sleep
    Map.pop(dict, key)
  end)
end
```

当一个耗时很长的运算发生在Server，所有其他提交到Server的请求
都要等待这个运算执行完毕，这可能会造成客户端超时。
