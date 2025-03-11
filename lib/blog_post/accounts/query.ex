defmodule BlogPost.Accounts.Query do
  import Ecto.Query

  alias BlogPost.Accounts.User

  def users() do
    from u in User, order_by: u.id
  end

  def created_before(query, date) when date |> is_nil(), do: query

  def created_before(query, date) do
    from q in query,
      where: q.created_at >= ^date
  end

  def by_permission_level(query, permission_level) when permission_level |> is_nil() do
    query
  end

  def by_permission_level(query, permission_level) do
    from u in query,
      where: u.permission_level == ^permission_level
  end
end
