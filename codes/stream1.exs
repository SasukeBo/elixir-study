[head | tail] =
  [1, 2, 3, 4]
  |> Stream.map(fn x -> x * x end)
  |> Stream.map(fn x -> x + 1 end)
  |> Stream.filter(fn x -> rem(x, 2) == 1 end)
  |> Enum.to_list()

IO.puts(head)
IO.puts(tail)
