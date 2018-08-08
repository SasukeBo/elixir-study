defmodule MyList do
  def span(from, to), do: do_span([to], from, to)

  defp do_span(list, from, to) when to > from do
    do_span([to - 1 | list], from, to - 1)
  end

  defp do_span(list, from, to) when to == from, do: list
end
