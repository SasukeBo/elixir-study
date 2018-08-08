## 散落的知识点

**推荐在Elixir项目开发中遇到的问题及时记录在本文档，需要时可以查询**

* 执行测试指定文件中的某个测试

    ```sh
    $ mix test test/word_filter_test.exs:25

    Including tags: [line: "25"]
    Excluding tags: [:test]

    .

    Finished in 0.07 seconds
    5 tests, 0 failures, 4 skipped

    Randomized with seed 39616
    ```

* 如何取得运行环境下的端口号

```elixir
defmodule WordFilter.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      supervisor(WordFilter.Repo, []),
      supervisor(WordFilter.Cache, []),
      supervisor(GRPC.Server.Supervisor, [
        {
          [
            WordFilter.Server
          ],
          # 获取当前环境下指定应用的端口号
          Application.get_env(:word_filter, :server_port)
        }
      ])
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: WordFilter.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
```

```elixir
use Mix.Config

config :logger, level: :warn

# 同时设置在测试环境下的config中，grpc非自动启动。
config :grpc, start_server: false

config :word_filter, :server_port, 51001

import_config "#{Mix.env()}.secret.exs"
```
