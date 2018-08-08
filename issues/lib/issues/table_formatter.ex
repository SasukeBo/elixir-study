defmodule Issues.TableFormatter do
  import Enum, only: [each: 2, map: 2, map_join: 3, max: 1]

  @doc """
  按列输出表格

  第一个参数是由Map组成的List，第二个参数是List，包含表头信息。
  在输出表格前，该函数计算了每列最长元素的长度，从而使输出显示整齐划一。
  """

  def print_table_for_columns(rows, headers) do
    data_by_columns = split_into_columns(rows, headers)
    column_widths = widths_of(data_by_columns)
    format = format_for(column_widths)

    [_head | tail] = headers
    puts_one_line_in_columns(["#" | tail], format)
    IO.puts(separator(column_widths))
    puts_in_columns(data_by_columns, format)
  end

  @doc """
  Given a list of rows, where each row contains a keyed list of columns,
  return a list containing lists of the data in each column. The `headers`
  parameter contains the list of columns to extract
  ## Example
    iex> list = [Enum.into([{"a", "1"},{"b", "2"},{"c", "3"}], Map.new),
    ...>         Enum.into([{"a", "4"},{"b", "5"},{"c", "6"}], Map.new)]
    iex> Issues.TableFormatter.split_into_columns(list, [ "a", "b", "c" ])
    [ ["1", "4"], ["2", "5"], ["3", "6"] ]
  """
  def split_into_columns(rows, headers) do
    for header <- headers do
      for row <- rows, do: printable(row[header])
    end
  end

  @doc """
  Return a binary (string) version of our parameter.
  ## Examples
     iex> Issues.TableFormatter.printable("a")
     "a"
     iex> Issues.TableFormatter.printable(99)
     "99"
  """
  def printable(str) when is_binary(str), do: str
  def printable(str), do: to_string(str)

  @doc """
  Given a list containing sublists, where each sublist contains the data for a column, return a list containing the maximum width of each column
  ## Example
     iex> data = [ [ "cat", "wombat", "elk"], ["mongoose", "ant", "gnu"]]
     iex> Issues.TableFormatter.widths_of(data)
     [ 6, 8 ]
  """
  def widths_of(columns) do
    for column <- columns, do: column |> map(&String.length/1) |> max
  end

  @doc """
  Return a format string that hard codes the widths of a set of columns. We put `" | "` between each column.
  ## Example
     iex> widths = [5,6,99]
     iex> Issues.TableFormatter.format_for(widths)
     "~-5ts | ~-6ts | ~-99ts~n"
  """
  def format_for(column_widths) do
    map_join(column_widths, " | ", fn width -> "~-#{width}ts" end) <> "~n"
  end

  @doc """
  Generate the line that goes below the column headings. It is a string of hyphens, with + signs where the vertical bar between the columns goes.
  ## Example
     iex> widths = [5,6,9]
     iex> Issues.TableFormatter.separator(widths)
     "------+--------+----------"
  """
  def separator(column_widths) do
    map_join(column_widths, "-+-", fn width -> List.duplicate("-", width) end)
  end

  @doc """
  Given a list containing rows of data, a list containing the header selectors,
  and a format string, write the extracted data under control of the format string.
  """
  def puts_in_columns(data_by_columns, format) do
    data_by_columns
    |> List.zip()
    |> map(&Tuple.to_list/1)
    |> each(&puts_one_line_in_columns(&1, format))
  end

  def puts_one_line_in_columns(fields, format) do
    :io.fwrite(format, fields)
  end
end
