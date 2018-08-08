defmodule PB do
  def make_total(tax_rates, orders) do
    for each_order <- orders, do: do_make(tax_rates, each_order)
  end

  def do_make(tax_rates, each_order) do
    [_, {_, location}, {_, net_amount}] = each_order

    if Enum.any?(tax_rates, fn {city, _rate} -> city == location end) do
      {_, rate} = Enum.find(tax_rates, fn {l, _p} -> l == location end)
      Enum.into([total_amount: net_amount * (1 + rate)], each_order)
    else
      each_order
    end
  end
end
