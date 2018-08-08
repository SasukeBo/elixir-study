defmodule MyApp.Hello do
  @moduledoc """
  This is the Hello module.
  """

  @doc """
  Says hello to the given `name`.

  Returns `:ok`.

  ## Examples

      iex> MyApp.Hello.world(:john)
      :ok

  """
  def world(string)
  def world(name) do
    IO.puts "hello #{name}"
  end
end

defmodule MyApp.Hidden do
  @moduledoc false

  @doc """
  This function won't be listed in docs.
  """
  def function_that_wont_be_listed_in_docs do
    # ...
  end
end

defmodule MyApp.Sample do
  @doc false
  def __add__(a, b), do: a + b

  @doc """
  This function will be listed in docs.
  """
  def show do
    __add__(1, 2)
  end
end
