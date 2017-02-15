defimpl Scrivener.Paginater, for: Ecto.Query do
  import Ecto.Query

  alias Scrivener.{Config, Page}

  @moduledoc false

  @spec paginate(Ecto.Query.t, Scrivener.Config.t) :: Scrivener.Page.t
  def paginate(query, %Config{page_size: page_size, page_number: page_number, module: repo}) do
    total_entries = total_entries(query, repo)

    %Page{
      page_size: page_size,
      page_number: page_number,
      entries: entries(query, repo, page_number, page_size),
      total_entries: total_entries,
      total_pages: total_pages(total_entries, page_size)
    }
  end

  defp entries(query, repo, page_number, page_size) do    
    offset = page_size * (page_number - 1)    
    
    if joins?(query) do   
      ids = query   
      |> remove_clauses   
      |> select([x], {x.id})    
      |> group_by([x], x.id)    
      |> offset([_], ^offset)   
      |> limit([_], ^page_size)   
      |> repo.all   
      |> Enum.map(&elem(&1, 0))   
    
      query   
      |> where([x], x.id in ^ids)   
      |> distinct(true)   
      |> repo.all   
    else    
      query   
      |> limit([_], ^page_size)   
      |> offset([_], ^offset)   
      |> repo.all   
    end   
  end   
    
  defp joins?(query) do   
    Enum.count(query.joins) > 0   
  end   
    
  defp remove_clauses(query) do   
    query   
    |> exclude(:preload)    
    |> exclude(:select)   
    |> exclude(:group_by)   
  end

  defp total_entries(query, repo) do
    total_entries =
      query
      |> exclude(:preload)
      |> exclude(:select)
      |> subquery
      |> select(count("*"))
      |> repo.one

    total_entries || 0
  end

  defp total_pages(total_entries, page_size) do
    (total_entries / page_size) |> Float.ceil |> round
  end
end
