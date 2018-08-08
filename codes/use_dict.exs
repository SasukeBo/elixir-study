defmodule Sum do
  def values(dict) do
    dict |> Dict.values() |> Enum.sum()
  end
end

# 对散列字典中的值求和
# Enum.into 可以方便地把一种类型的收集映射成另一种。
hd = [one: 1, two: 2, three: 3] |> Enum.into(HashDict.new())
IO.puts(Sum.values(hd))

# 对散列表中的值求和。
map = %{four: 4, five: 5, six: 6}
IO.puts(Sum.values(map))
