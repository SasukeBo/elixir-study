IO.puts(
  File.read!("./../README.md")
  |> String.split()
  |> Enum.max_by(&String.length/1)
  |> IO.inspect()
)
