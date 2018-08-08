defmodule My do
  defmacro if(condition, clauses) do
    do_clause = Keyword.get(clauses, :do, nil)
    else_clause = Keyword.get(clauses, :else, nil)

    quote do
      case unquote(condition) do
        val when val in [false, nil] -> unquote(else_clause) |> IO.inspect
        _ -> unquote(do_clause) |> IO.inspect
      end
    end
  end
end

# defmodule Test do
#   require My
#
#   My.if 1 == 2 do
#     "Yes"
#   else
#     "No"
#   end
# end

defmodule Times do
  defmacro times_n(num) do
    quote do
      def unquote(:"times_#{num}")(factor), do: factor * unquote(num)
    end
  end
end

defmodule Test do
  require Times

  Times.times_n(3)
  Times.times_n(4)
end

defmodule My2 do
  defmacro mydef(name) do
    quote do
      def unquote(name)(), do: unquote(name)
    end
  end
end

defmodule My3 do
  defmacro mydef(name) do
    quote bind_quoted: [name: name] do
      def unquote(name)() do
        name = "Hello #{unquote(name)}"
        unquote(name |> IO.inspect)
      end
    end
  end
end

defmodule Test3 do
  require My3

  [:fred, :bert] |> Enum.each(&My3.mydef(&1))
end
