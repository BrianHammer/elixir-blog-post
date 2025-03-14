defmodule BlogPost.Blog.Query do
  import Ecto.Query

  alias BlogPost.Blog.Article

  def articles() do
    from a in Article, order_by: a.inserted_at
  end

  def with_author(query) do
    from q in query,
      preload: :user
  end

  def created_before(query, date) when date |> is_nil(), do: query

  def created_before(query, date) do
    from q in query,
      where: q.created_at >= ^date
  end


  def by_author(query, user = %BlogPost.Accounts.User{}) do
    id = user.id
    from q in query, where: q.user_id == ^id
  end


end
