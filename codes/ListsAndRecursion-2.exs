defmodule MyList do
  def max(list), do: hmax(list, 0)

  defp hmax([], value), do: value
  defp hmax([head | tail], value) when head > value, do: hmax(tail, head)
  defp hmax([head | tail], value) when head <= value, do: hmax(tail, value)
end
