defmodule MyList do
  def caesar([], _n), do: []

  def caesar([head | tail], n) do
    [do_caesar(head, n) | caesar(tail, n)]
  end

  defp do_caesar(head, n) do
    ?a + rem(head + n - ?a, 26)
  end
end
