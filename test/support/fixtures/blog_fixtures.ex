defmodule BlogPost.BlogFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `BlogPost.Blog` context.
  """

  @doc """
  Generate a article.
  """
  def article_fixture(attrs \\ %{}) do
    {:ok, article} =
      attrs
      |> Enum.into(%{
        content: "some content",
        image_url: "some image_url",
        title: "some title"
      })
      |> BlogPost.Blog.create_article()

    article
  end
end
