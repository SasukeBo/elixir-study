defmodule Users do
  dave = %{ name: "Dave", state: "TX", likes: "Programming" }

  case dave do
    person = %{state: _} ->
      IO.puts "#{person.name} lives in #{person.state}"

    %{likes: likes} = person ->
      IO.puts "#{person.name} likes #{likes}"

    _ ->
      IO.puts "No matches"
  end
end

defmodule Bouncer do

  dave = %{name: "Dave", age: 27}

  case dave do
    %{age: age} = person when is_number(age) and age >= 21 ->
      IO.puts "You are cleared to enter the Foo Bar, #{person.name}"
    _ ->
      IO.puts "Sorry, no admission"
  end
end

defmodule RaiseMessage  do
  def open_a_file(file_name) do
    case File.open(file_name) do
      {:ok, file} ->
        Enum.each(IO.stream(file, :line), &IO.puts/1)
      {:error, message} ->
        IO.puts :stderr, "Couldn't open #{file_name}: #{message}"
    end
  end
end
