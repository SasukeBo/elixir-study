defmodule ExampleTest do
  use ExUnit.Case

  setup do
    {:ok, number: 2}
  end

  test "the truth", state do
    assert 1 + 1 == state[:number]
  end
end
