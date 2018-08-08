# Testing

测试是软件开发的重要组成部分。

## ExUnit

Elixir内置的测试框架是ExUnit，它包含了几乎所有测试需要的东西。
需要注意的是，测试是基于elixir脚本实现的，所以文件后缀要用`.exs`。
在运行测试之前我们还需要先执行`ExUnit.start()`来启动测试单元，
通常将这行代码写在`test/test_helper.exs`文件中。

当我们创建一个Elixir项目时，mix会自动生成一个简单的测试文件，
我们可以在test目录下找到`project_test.exs`（project是你的项目名）:

```elixir
defmodule IssuesTest do
  use ExUnit.Case
  doctest Issues

  test "greets the world" do
    assert Issues.hello() == :world
  end
end
```
`doctest Issues`会测试Issues模块函数文档中的`iex>`后面的代码与第二行给出的期望结果是否匹配。

我们可以使用`mix test`来运行项目的测试。

### assert

我们使用`assert`宏来测试表达式是否正确。如果表达式结果不正确则会报错：

```cmd
......

  1) test greets the world (IssuesTest)
     test/issues_test.exs:5
     Assertion with == failed
     code:  assert Issues.hello() == :World
     left:  :world
     right: :World
     stacktrace:
       test/issues_test.exs:6: (test)

....

Finished in 0.06 seconds
6 doctests, 5 tests, 1 failure

Randomized with seed 97461
```

ExUnit会告诉我们哪里出错、期望得到的结果和实际得到的结果。

### refute

`refute`与`assert`就像`if`和`unless`，当表达式结果不正确时，测试测试才会通过。

```cmd
.....

  1) test greets the world (IssuesTest)
     test/issues_test.exs:5
     Refute with == failed, both sides are exactly equal
     code: refute Issues.hello() == :world
     left: :world
     stacktrace:
       test/issues_test.exs:6: (test)

.....

Finished in 0.06 seconds
6 doctests, 5 tests, 1 failure

Randomized with seed 416668
```

### assert_raise

有时候会断言某个错误被抛出，我们可以使用assert_raise

### assert_receive

在Elixir语言中，会有很多进程之间会互相发消息，就需要测试某些消息是否被发送。
因为ExUnit是运行在自己的process中，因此可以像其他process一样接收消息。

我们来测试一下：

新建一个文件`issues/sending_process.ex`:

```elixir
defmodule SendingProcess do
  def run(pid) do
    send(pid, :ping)
  end
end
```

新建一个测试文件`receive_test.exs`：

```elixir
defmodule TestReceive do
  use ExUnit.Case

  test "receives ping" do
    SendingProcess.run(self())
    assert_received :pin # 为了看到测试失败结果我们假设收到的消息是:pin
  end
end
```

* 注意，测试文件的命名格式必须是`name_test.exs`，否则执行`mix test`时不会运行你编写的测试文件。

测试失败时大概这样：

```cmd

  1) test receives ping (ReceiveTes)
     test/receiv_test.exs:4
     No message matching :ing after 0ms.
     Process mailbox:
       :ping
     code: assert_received :ing
     stacktrace:
       test/receiv_test.exs:6: (test)



Finished in 0.06 seconds
6 doctests, 6 tests, 1 failure

Randomized with seed 579084
```

### capture_io和capture_log

使用`ExUnit.CaptureIO`可以在不改变原来应用的情况下捕获应用的输出。
只要把生成输出的函数作为参数传递进去就行：

我们来写一个测试：

```elixir
defmodule OutputTest do
  use ExUnit.Case
  import ExUnit.CaptureIO

  test "outputs Hello World" do
    assert capture_io(fn -> IO.puts("Hello World") end) == "Hello World\n"
  end
end
```

`ExUnit.CaptureLog`就是捕获`Logger`的输出。

## Test配置

测试之前可以先做一些配置，会用到`setup`和`setup_all`这两种宏。

`setup`在某个测试用例之前都会被运行，`setup_all`只会在整套测试之前运行一次。
它们两的返回值是元组：`{:ok, state}`，其中`state`可以再后续的测试中被使用。

例如：

```elixir
defmodule ExampleTest do
  use ExUnit.Case

  setup_all do
    {:ok, number: 2}
  end

  test "the truth", state do
    assert 1 + 1 == state[:number]
  end
end
```

参考资料：

* [HexDocs ExUnit](https://hexdocs.pm/ex_unit/ExUnit.html#content)
* [Testing · Elixir School](https://elixirschool.com/en/lessons/basics/testing/)
