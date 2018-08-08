defmodule ControlFlow do

  def upto(n) when n > 0, do: _upto(1, n, [])

  def _upto(_current, 0, result), do: Enum.reverse result

  def _upto(current, left, result) do
    next_answer =
      case rem(current, 3) do
        0 ->
          case rem(current, 5) do
            0 -> "FizzBuzz"
            _ -> "Fizz"
          end
        _ ->
          case rem(current, 5) do
            0 -> "Buzz"
            _ -> current
          end
      end
    _upto(current + 1, left - 1, [next_answer | result])
  end

  def ok!(param) do
    case param do
      {:ok, data} ->
        data
      {:error, message} ->
        raise "The file couldn't be open: #{message}"
      _ ->
        raise "The \"#{param}\" couldn't be processed!"
    end
  end
end
