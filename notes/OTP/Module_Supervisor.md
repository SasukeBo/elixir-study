# Superviosr

Supervisor 是用于管理其他子进程的进程。被用于构造一个等级制的进程结构，叫做Supervisor树。
Supervisor树提供容错性，包含了如何启动和停止我们的应用。

Supervisor可以直接通过start_link方法和子进程队列一起启动，或者定义一个基于Supervisor并且实现了回调函数的模块。

## Examples

为了启动一个Supervisor，我们需要先定义一个被管理的子进程。
下面的例子定义了一个GenServer，代表了一个栈。
```elixir
defomdule Stack do
  user GenServer

  def start_link(state) do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  @impl true
  def init(stack) do
    {:ok, stack}
  end

  @impl true
  def handle_call(:pop, _from, [head | tail]) do
    {:reply, head, tail}
  end

  @impl true
  def handle_cast({:push, head}, tail) do
    {noreply, [head | tail]}
  end
end
```

现在我们可以启动一个Suprevisor来启动我们的栈进程。首先需要定义一个children list，
用来指定每个子进程的配置（child specifications），每一个specification都是一个map，如下：

```elixir
children = [
  # The Stack is a child started via Stack.start_link([:hello])
  %{
    id: Stack,
    start: {Stack, :start_link, [[:hello, :sasuke]]}
  }
]

# Now we start the supervisor with the children and a strategy
{:ok, pid} = Supervisor.start_link(children, strategy: :one_for_one)

# After started, we can query the supervisor for information
Supervisor.count_children(pid)
#=> %{active: 1, specs: 1, supervisors: 0, workers: 1}
```

当我们启动GenServer时，我们已经将它的名字注册为Stack，这样可以直接用这个名字来获取栈中的元素：

```elixir
GenServer.call(Stack, :pop)
#=> :hello

GenServer.cast(Stack, {:push, :world})
#=> :ok

GenServer.call(Stack, :pop)
#=> :world
```

然而我们的stack server有一个bug，如果栈是空的，我们调用:pop就会发生错误
但是，此时Supervisor的作用就发挥了，它会自动重启一个新的Stack，此时你再:pop会发现栈中仍然有:hello。

Supervisor支持不同的策略；上面的例子我们选择的是`:one_for_one`。
除此以外，Supervisor可以拥有很多worker或者supervisor作为子进程，每个子进程都有自己的配置（Child Specification）

接下来会介绍子进程是怎么启动的，如何配置它们，以及不同的管理策略，等等。

## Start and shutdown

Supervisor启动时会按定义顺序遍历配置并启动所有的子进程。
这一过程通过调用:start指定的function来实现，默认的方法就是start_link。
上例中就是Stack模块的start_link方法。

每一个子进程的start_link方法都会被调用，且start_link方法必须返回`{:ok,  pid}`，
这个进程id被用来关联到Supervisor。子进程通过init方法来启动它的工作。
通俗的来说，就是在init方法中初始化和配置子进程。

进程的关闭顺序和开启顺序相反。

当Supervisor关闭时，它会按照children列表的反顺序终止所有的子进程。
通过发送一个关闭信号给子进程（`Process.exit(child_pid, :shutdown)`），然后等待一定时间让其终止。
这个等待时间默认是5000毫秒。如果超时任未关闭，Supervisor则会杀死这个进程。
关闭时间可以在定义children列表时配置，后面会讲到。

## Child specification

child specification 指明了Supervisor如何启动、停止和重启子进程。
child specification包含了6个键值对。前两个是必要参数，其余参数为可选：

* `:id`-标识子进程，一般为模块名。当命名冲突时需要指定详细的ID。
* `:start`-一个元组，包含了模块名、方法名和参数，当启动子进程时会调用这个模块的这个方法。
* `:restart`-原子，指定什么时候重启子进程，默认值是`:permanent`。
* `shutdown`-原子，指明子进程该如何被关闭，子进程是worker时默认值为5000，
子进程是一个supervisor树时默认值为`:infinity`。
* `:type`-指明子进程是一个worker还是一个supervisor数，默认是`:worker`。
* 第六个key是`modules`，这个参数很少发生变化，它会根据start的值被自动设置。


### Shutdown values(:shutdown)

* `:brutal_kill` 立刻停止，通过调用`Process.exit(child, :kill)`
* `任何大于等于0的整数` 毫秒为单位的时间，Supervisor等待子进程终止的时间不会超过这个时间。
* `:infinity` 如果子进程是一个supervisor，建议给定`:infinity`，使其有足够的时间等待其子进程的关闭。
但是不建议对worker使用，因为很容易造成子进程无法终止，最终导致应用无法停止。

### Restart values(:restart)

`:restart`选项控制Supervisor重启子进程策略，Supervisor需要判断子进程的关闭是正常关闭还是崩溃退出。
一般正常退出的子进程不会被重启，而崩溃的子进程Supervisor则会启动一个新的。

* `:permanent` 子进程总是会被重启
* `:temporary` 子进程永远不会被重启，无视supervisor策略，所有的进程退出都被视为正常退出。
* `:transient` 只有在进程非正常退出时才会重启。


### child_spec/1

当启动supervisor时，我们传入了子进程配置列表。这些配置都是map，例如：

```elixir
%{
  id: Stack,
  start: {Stack, :start_link, [[:hello]]}
}
```

这个map定义了一个子进程，启动时调用`Stack.start_link([:hello])`。
也写成元组：

```elixir
children = [
  {Stack, [:hello]}
]
```

这样定义子进程时，Supervisor会调用`Stack.child_spec([:hello])`方法，它会返回之前的map格式。
这一方法通过`use GenServer`获得。
甚至可以只写一个模块名，那样就不对应任何参数

```elixir
children = [
  Stack
]
```

总的来说，定义child specification可以是以下的三种形式：

* 一个map，代表了了child specification本身
* 一个元组，第一个元素是模块名，第二个元素是启动参数，诸如`Stack.child_spec([args1, args2])`的方法会被调用来获得child specification。
* 一个模块名，这种情况将会调用类如`Stack.child_spec([])`方法来获得child specification。

还可以通过直接调用`child_spec`方法定义child specification:

```elixir
children = [
  Supervisor.child_spec({Stack, [:hello]}, id: MyStack, shutdown: 10_000)
]
```

这样可以不同的`:id`-MyStack来启动子进程，上面例子的`child_spec`会返回这样的结果：

```elixir
%{
  id: MyStack,
  start: {Stack, :start_link, [[:hello]]},
  shutdown: 10_000
}
```
还可以通过在模块中指定不一样的`:id`

```elixir
defmodule Stack do
  use GenServer, id: MyStack, shutdown: 10_000
  ...
end
```

上面的写法会影响use GenServer生成的Stack.child_spec/1方法。它接收的参数和Supervisor.child_sepc/2一样。

你也完全可以重写Stack模块内的child_spec/1方法，返回你自己需要的child specification。
需要注意的是，child_spec/1方法不一定会被Supervisor进程调用，因为其他应用可能会赶在Supervisor之前调用它。

### Exit reasons and restarts

Supervisor重启子进程取决于:restart配置。
例如，:transient设置，Supervisor只会重启那些退出原因除:normal, :shutdown 或 {:shutdown, term}之外的进程。


## Module-based supervisor

在上面的所有例子，supervisor启动都是通过传递supervision结构给start_link/2方法。
然而，supervisors还可以直接通过定义supervision模块生成：

```elixir
defmodule MyApp.Supervisor do
  # Automatically defines child_spec/1
  use Supervisor

  def start_link(arg) do
    Supervisor.start_link(__MODULE__, arg, name: __MODULE__)
  end

  @impl true
  def init(_arg) do
    children = [
      {Stack, [:hello]}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
```

基于模块的supervisor的好处是可以直接控制如何初始化supervisor，`use Superviosr`定义了`child_spec/1`，
使得我们可以让`MyApp.Superviosr`作为子进程运行：

```elixir
children = [
  MyApp.Superviosr
]

Superviosr.start_link(children, strategy: :one_for_one)
```

建议在应用在使用基于module的supervisor作为其他supervisor的子进程。
然后使用一个没有回调函数的模块来作为顶层的supervisor，一般是项目的`Application`模块。

### Strategies

重启策略
* `:one_for_one` 一个进程退出，只重启这个退出的进程
* `:one_for_all` 一个进程退出，所有的进程重启
* `:rest_for_one` 一个进程退出，重启这个进程和进程队列中排在这个进程之后的所有进程。
