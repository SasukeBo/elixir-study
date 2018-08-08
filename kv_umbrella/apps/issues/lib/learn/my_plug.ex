defmodule MyPlug do
  import Plug.Conn

  def init(options) do
    # initialize options

    options
  end

  def call(conn, opts) do
    hello_world_plug(conn, opts)
  end

  def hello_world_plug(conn, opts) do
    conn
    |> put_resp_content_type("text/plain")
    |> send_resp(200, "Hello world plug #{opts[:value]}")
  end

end
