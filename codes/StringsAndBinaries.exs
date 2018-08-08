defmodule MyStrings do
  import String

  def is_ASCII([head | tail]) when is_list([head | tail]) do
    if head > ?\s - 1 && head < ?~ + 1 do
      is_ASCII(tail)
    else
      false
    end
  end

  def is_ASCII([]), do: true

  def anagram?(word1) do
    Enum.reverse(word1) == word1
  end

  def calculate(expression) when is_list(expression) do
    analyze(expression, 0)
  end

  defp analyze([head | tail], value) when head >= ?0 and head <= ?9 do
    analyze(tail, value * 10 + (head - ?0))
  end

  defp analyze([head | tail], value) when head == ?+ do
    value + analyze(tail, 0)
  end

  defp analyze([head | tail], value) when head == ?- do
    value - analyze(tail, 0)
  end

  defp analyze([head | tail], value) when head == ?* do
    value * analyze(tail, 0)
  end

  defp analyze([head | tail], value) when head == ?/ do
    value / analyze(tail, 0)
  end

  defp analyze([head | tail], value) when head == ?\s do
    analyze(tail, value)
  end

  defp analyze([], value), do: value

  # 编写一个函数，接受一个双引号字符串列表作为参数，并将每个字符串打印在单独一行
  # 上，以最长字符串的宽度来居中对齐。

  def center(string_list) do
    count_size_max(string_list, 0) |> print_str(string_list)
  end

  defp count_size_max([head | tail], max_size) do
    if byte_size(head) > max_size do
      count_size_max(tail, byte_size(head))
    else
      count_size_max(tail, max_size)
    end
  end

  # defp count_size_max([], max_size), do: max_size
  defp count_size_max([], max_size) do
    max_size
  end

  defp print_str(max_size, string_list) do
    for str <- string_list do
      lsize = (max_size - byte_size(str)) |> div(2)
      pad_leading(str, String.length(str) + lsize) |> IO.puts()
    end
  end

  # 编写一个函数读取和解析文件tax_data，得出的结果可以由ListsAndRecursion-8.exs文件中定义的方法make_total处理。
  def read_tax_data(str) do
    {:ok, file} = File.open(str)
    stream = IO.stream(file, :line)
    list = for str <- stream, do: String.trim_trailing(str, "\n") |> String.split(",")
    return_a_list(list, 0, [], [])
  end

  defp return_a_list([head | tail], i, list_head, good_list) do
    if i == 0 do
      return_a_list(tail, 1, tran_key_map(head), good_list)
    else
      return_a_list(tail, 1, list_head, good_list ++ [Enum.zip(list_head, tran_data_map(head))])
    end
  end

  defp return_a_list([], _, _, good_list), do: good_list

  defp tran_key_map(list) do
    for str <- list, do: String.to_charlist(str) |> List.to_atom
  end

  defp tran_data_map([id, city, net_amount]) do
    [
      String.to_integer(id),
      String.trim_leading(city,":") |> String.to_atom,
      String.to_float(net_amount)
    ]
  end
end
