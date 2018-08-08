defmodule Utf8 do
  def each(str, func) when is_binary(str), do: _each(str, func)

  defp _each(<< head :: utf8, tail :: binary >>, func) do
    func.(head)
    _each(tail, func)
  end

  defp _each(<<>>, _func), do: []

  def capitalize_sentences(str) do
    list = String.split str, ~r{(\.\s)}, include_captures: true
    str_list = for str <- list , do: String.capitalize(str, :ascii)
    Enum.reduce(str_list, fn(str, total_str) -> total_str <> str end)
  end

end
