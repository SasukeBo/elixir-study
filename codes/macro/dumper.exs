defmodule My do
  def myif(condition, clauses) do
    do_clauses = Keyword.get(clauses, :do, nil)
    else_clauses = Keyword.get(clauses, :else, nil)

    case condition do
      val when val in [false, nil] ->
        else_clauses

      _otherwise ->
        do_clauses
    end
  end
end
