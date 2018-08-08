defmodule MyUniqList do
  def uniq(enumerable) do
    uniq_by(enumerable, fn x -> x end)
  end

  def uniq_by(enumerable, fun) when is_list(enumerable) do
    uniq_list(enumerable, %{}, fun)
  end

  defp uniq_list([head | tail], set, fun) do
    value = fun.(head)

    case set do
      %{^value => true} -> uniq_list(tail, set, fun)
      %{} -> [head | uniq_list(tail, Map.put(set, value, true), fun)]
    end
  end

  defp uniq_list([], _set, _fun) do
    []
  end
end
