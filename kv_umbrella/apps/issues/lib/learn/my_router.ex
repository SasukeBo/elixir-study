defmodule MyRouter do
  use Plug.Router
  require EEx

  plug :match
  plug :dispatch

  get "/hello" do
    send_resp(conn, 200, "world")
  end

  get "/hello/*glob" do
    send_resp(conn, 200, EEx.eval_string("foo <%= bar %>", [bar: glob]))
  end
  get "/hello/*_rest" do
    send_resp(conn, 200, "matches all routes starting with /hello")
  end

  forward "/users", to: MyPlug
  forward "/index", to: MyPlug, init_opts: [an_option: :hello_world_plug]


  match _ do
    send_resp(conn, 404, "oops")
  end
end
