IO.puts(
  File.open!("./../README.md")
  |> IO.stream(:line)
  |> Enum.max_by(&String.length/1)
)
