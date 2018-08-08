# Elixir文档规范和mix format

## Writing Documentation

Elixir很注重文档，Elixir的文档应该做到易读易写。

下面我们学习一下如何在Elixir中写文档。

### Markdown

Elixir 的文档是用Markdown格式来写的。

### Module Attribute

Elixir的文档通常是和模块相关联的，让我们看一个例子：

```elixir
defmodule MyApp.Hello do
  @moduledoc """
  This is the Hello module.
  """

  @doc """
  Says hello to the given `name`.

  Returns `:ok`.

  ## Examples

      iex> MyApp.Hello.world(:john)
      :ok

  """
  def world(name) do
    IO.puts "hello #{name}"
  end
end
```

其中`@moduledoc`是用来添加模块文档，`@doc`用来为一个方法添加文档。
除此之外还有一个`@typedoc`可以为type添加文档。

### 函数标准说明(Function specifications)

通常Elixir提供一些基础的数据类型，例如integer或者pid，当我们书写函数文档时，会介绍
函数接收的参数类型以及返回的参数类型。例如：

```elixir
@spec to_list(t()) :: [element()]
```

这表示Enum.to_list函数接收参数类型是t，而查阅文档可以看到对应关系`@type t :: Enumerable.t()`，
而返回的数据是element()类型的。

* 用户自定义类型

由于Elixir提供了很多内置类型，基于此自定义类型是很方便的。
例如这里有一个模块`LousyCalculator`，处理一些常见的算术运算，但是这些算术运算函数
返回的是元组，包含了运算结果和一段对应的字符串:

```elixir
defmodule LousyCalculator do
  @spec add(number, number) :: {number, String.t}
  def add(x, y), do: {x + y, "You need a calculator to do that?!"}

  @spec multiply(number, number) :: {number, String.t}
  def multiply(x, y), do: {x * y, "Jeez, come on!"}
end
```
如上所示，返回值类型是一个由number和String.t构成的元组。（了解更多String.t而不是String，请
点击[notes in the typespecs docs](https://hexdocs.pm/elixir/typespecs.html#notes)）

以这种方式定义函数的返回值是有效的，但是却渐渐被`@type`定义返回值类型的手段所取代。
请看下面的代码：

```elixir
defmodule LousyCalculator do
  @typedoc """
  Just a number followed by a string.
  """
  @type number_with_remark :: {number, String.t}

  @spec add(number, number) :: number_with_remark
  def add(x, y), do: {x + y, "You need a calculator to do that?"}

  @spec multiply(number, number) :: number_with_remark
  def multiply(x, y), do: {x * y, "It is like addition on steroids."}
end
```

这里使用了`@type`定义`number_with_remark`来替代`{number, String.t}`。
用`@typedoc`对自定义的类型做了解释。

并且，这种自定义的类型还可以在模块外部被调用：

```elixir
defmodule QuietCalculator do
@spec make_quiet(LousyCalculator.number_with_remark) :: number
  defp make_quiet({num, _remark}), do: num
end
```

如果你想定义一个私有的type，请使用`@typep`。


### 文档书写规范建议

* 保证文档的第一段简明扼要，一般只写一行，像ExDoc这样的工具一般都用第一行去生成一个总结。
* 请使用完整的Module名字，例如`MyApp.Hello`模块需要引用完整名字，而不是`Hello`。
* 引用方法名需要带上参数格式，例如：`world/1`，或者：`MyApp.Hello.world/1`。
* 引用`@callback`需要加前缀`c:`，例如：`c:world/1`。
* 引用`@type`需要加前缀`t:`，例如：`t:values/0`。
* 一级标题是为Module和function的名字保留的，所以，当书写新的文档部分时要用二级标题`##`。
* 当一个函数有多个函数体，请将文档内容置于第一个函数体之前。请不要将文档穿插在函数体之间。

### Doctests

建议开发人员在文档中书写examples，一般在二级标题`##Examples`之下。为了保证这些例子不会过时，
Elixir的测试模块提供了一个特性叫做doctests，这可以让开发者在文档中测试他们写的例子！
Doctests解析文档中以`iex>`开头的代码，了解更多可以去查阅`ExUnit.DocTest`。

但是doctests有一定的局限性，当你为方法写的例子在运行时受其他环境影响，就不能使用doctest，
这种情况下建议直接去掉`iex>`。


### Documentation != Comments

Elixir视Documentation和Comments为两个不同的概念。文档是写给将使用你写的API的用户来阅读的。
而Code Comments是用来给开发者阅读的，在做标记和notes时非常有用。
换一句话说，documentation是必须的，而code comments是按需求来写的。

Code comments:

```elixir
defmodule Maths do
  def add(left, right) do
  # Add two numbers together
  left + right
  end
end
```

### Hiding Internal Modules and Functions

库(Library)中除了那些作为API提供给用户的Modules和Functions，还有一些实现了重要功能的代码，
但是不会作为API提供给用户，这些部分称为库的内部代码（内部模块和内部方法等），而这些部分就
不应该为终端用户提供文档。

也就是说，并不是你写的所有代码都要附加上公开的文档。而是要考虑哪些功能是作为API提供出去的。

因此，Elixir为开发者提供了隐藏这些功能模块的办法。

```elixir
defmodule MyApp.Hidden do
  @moduledoc false

  @doc """
  This function won't be listed in docs.
  """
  def function_that_wont_be_listed_in_docs do
    # ...
  end
end
```

通过设置`@moduledoc`为`false`，可以隐藏这个module的文档。

类似的可以设置`@doc`为`false`来隐藏Function的文档。

```elixir
defmodule MyApp.Sample do
  @doc false
  def add(a, b), do: a + b

  @doc """
  This function will be listed in docs.
  """
  def show do
    # ...
  end
end
```

我们来测试一下

```
iex> c "write_documentation.exs", "."
iex> h MyApp.Sample.show
iex> h MyApp.Sample.add
```

需要注意的是，`@doc false`和函数私有没有任何关系！这些函数仍然可以外部调用。
所以，如果需要为函数添加`@doc false`时，可以考虑下面两种选择：

* 把没有文档的函数移动到设置了`@moduledoc false`的模块里，就如上面的`MyApp.Hidden`。
确保这些函数不会不小心暴露出来或是被import。

* 命名函数时以两个'_'开始，例如：`__add__/2`，并且加上`@doc false`，编译器不会import
这样命名的函数，这样命名也是暗示代码阅读者，这个函数的作用是私有的。

我们来试试第二条选择。

```elixir
defmodule MyApp.Sample do
  @doc false
  def __add__(a, b), do: a + b

  @doc """
  This function will be listed in docs.
  """
  def show do
    __add__(1, 2)
  end
end
```

```
iex> import MyApp.Sample
iex> show
```
而使用`iex> __add__(1, 2)`时就会报错，提示`undefined function __add__/2`。

### Documenting Private Functions

当你为Private函数写文档时，Elixir会发出警告！因为`@doc`存在的意义就是为public借口添加文档，
既然是私有函数，那么久没有写文档的意义，*注意不要混淆私有函数和内部函数！*

私有函数可能也需要内部的文档用于给拥有者阅读，可以使用comments来完成这个需求。

### Code.get_docs/2

Elixir在预定义块中按字节存储文档，可以通过`Code.get_docs/2`来获取这些文档的全部或部分。
我将前面的Module例子都写在一个write_documentation.exs文件中，我们在iex中编译这个文件。

```
iex> c "write_documentation.exs", "."
```
后面的参数表示在当前路径下存储documentation的字节文件，执行后可以看到我的目录下多了三个文件：

```
Elixir.MyApp.Hello.beam
Elixir.MyApp.Hidden.beam
Elixir.MyApp.Sample.beam
```
再来试试`Code.get_docs/2`

```
iex> Code.get_docs MyApp.Hello, :docs
```

会返回这个列表：

```elixir
[
  {{:world, 1}, 6, :def, [{:string, [], nil}],
   "Says hello to the given `name`.\n\nReturns `:ok`.\n\n## Examples\n\n    iex> MyApp.Hello.world(:john)\n    :ok\n\n"}
]
```

如果你删掉`Elixir.MyApp.Hello.beam`这个文件，上面的命令会Raise一个Error。

[参考资料链接](https://hexdocs.pm/elixir/writing-documentation.html)

### ExDoc

ExDoc是个用于为你的Elixir项目生成文档（documentation）的工具。
用于描述你的项目、模块、模块中定义的东西，以及编写的任何文档内容，就像你在https://hexdocs.pm/elixir/ 上看到那样。

github地址：[ExDoc on GitHub](https://github.com/elixir-lang/ex_doc)。

具体用法官网记录很详细，就不累述了。

测试了一下，`mix docs`之后会在项目根目录下生成一个doc目录，里面就是ExDoc为你生成的文档工具。
直接在浏览器打开`index.html`就可以使用。

## Mix Format

格式化给定的文件或者满足匹配模式的文件。

```
$ mix format ./example.exs
```

### Formatting options

formatter的配置文件名为`.formatter.exs`，一般在项目主目录下。

`.formatter.exs`支持以下选择：

* `:inputs`(由路径或者匹配模式构成的列表)，配置默认的格式化文件，一般项目默认配置是`["mix.exs", "{config,lib,test}/**/*.{ex,exs}"]`。

    来试一试：在项目主目录下编写一个`.exs`文件，但是内容不符合格式规范，我们先不配置这个文件为默认的格式化文件，
    然后执行`$ mix format`，然后将这个文件配置到`:inputs`，再执行`$ mix format`，看看前后效果。

* `:subdirectories`(由路径或者匹配模式构成的列表)，指定子目录的格式化规则。经过测试，大概逻辑是：

    在项目主目录下的.formatter.exs配置`:subdirectories`，指定需要特殊格式化规则的子目录(就是想要不同于父目录格式化规则时)，并且，也需要创建一个.formatter.exs文件，
    用来配置该子目录中的文件格式化规则。但要想确保该子目录的.formatter.exs生效，就不能在它的父目录的.formatter.exs的`:inputs`中
    配置该子目录，否则会发生覆盖。子目录的子目录同样可以遵循这个逻辑。

* `:import_deps`
* `:export`


### Task-specific options

* `--check-formatted` 检查文件是否已经被格式化了。

    例如我检查一个叫`todo_format.exs`的文件，这个文件未被格式化

    ```
    $ mix format --check-formatted ./todo_format.exs
    ```
    会返回这样的结果：

    ```
    ** (Mix) mix format failed due to --check-formatted.
    The following files were not formatted:

      * todo_format.exs
    ```

* `--check-equicalent`  check if the files after formatting have the same AST as before formatting. If the ASTs are not equivalent, it is a bug in the code formatter.
* `--dry-run` 格式化文件但不保存
* `--dot-formatter` 指定按照哪个`.formatter.exs`的规则来执行格式化


### When to format code

建议开发者直接在编辑器里格式化代码，或者保存文件的时候，最好是你自己就能写出规范的代码。

[参考资料链接](https://hexdocs.pm/mix/master/Mix.Tasks.Format.html)

### vim-mix-format

这是一款让你可以再vim中mix format的插件

[vim-mix-format on GitHub](https://github.com/mhinz/vim-mix-format)

可以再vim配置文件设置保存文件时自动format。
