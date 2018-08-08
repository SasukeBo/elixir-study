defmodule Issues.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(type, args) do
    # args 来自mix.exs的application函数中的配置
    IO.inspect [type, args]
    import Supervisor.Spec, warn: false

    IO.puts("application start!")

    children = [
      Plug.Adapters.Cowboy.child_spec(scheme: :http, plug: MyRouter, options: [port: Application.get_env(:issues, :port)]),
      Issue.Supervisor,
      KV.Supervisor
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Issues.Supervisor]

    Supervisor.start_link(children, opts)
  end
end
