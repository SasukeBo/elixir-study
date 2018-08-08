defmodule Chop do
  def guess(actual, range) do
    IO.puts("Is it #{midway(range)}")
    test_guess(actual, midway(range), range)
  end

  defp test_guess(actual, guess, _) when actual == guess do
    IO.puts(guess)
  end

  defp test_guess(actual, guess, _..upper) when actual > guess do
    guess(actual, guess..upper)
  end

  defp test_guess(actual, guess, lower.._) when actual < guess do
    guess(actual, lower..guess)
  end

  defp midway(lower..upper) do
    div(upper + lower, 2)
  end
end
