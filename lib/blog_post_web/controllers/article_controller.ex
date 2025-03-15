defmodule BlogPostWeb.ArticleController do
  use BlogPostWeb, :controller

  alias BlogPost.Blog
  alias BlogPost.Blog.Article

  def index(conn, _params) do
    articles = Blog.list_articles()
    # render(conn, :index, articles: articles)
    conn
    |> assign(:articles, articles)
    |> render(:index)
  end

  def new(conn, _params) do
    changeset = Blog.change_article(%Article{})
    render(conn, :new, changeset: changeset)
  end

  def create(conn, %{"article" => article_params}) do
    case Blog.create_article(article_params) do
      {:ok, article} ->
        conn
        |> put_flash(:info, "Article created successfully.")
        |> redirect(to: ~p"/articles/#{article}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :new, changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    article = Blog.get_article!(id)
    render(conn, :show, article: article)
  end

  def edit(conn, %{"id" => id}) do
    article = Blog.get_article!(id)
    changeset = Blog.change_article(article)
    render(conn, :edit, article: article, changeset: changeset)
  end

  def update(conn, %{"id" => id, "article" => article_params}) do
    article = Blog.get_article!(id)

    case Blog.update_article(article, article_params) do
      {:ok, article} ->
        conn
        |> put_flash(:info, "Article updated successfully.")
        |> redirect(to: ~p"/articles/#{article}")

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, :edit, article: article, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    article = Blog.get_article!(id)
    {:ok, _article} = Blog.delete_article(article)

    conn
    |> put_flash(:info, "Article deleted successfully.")
    |> redirect(to: ~p"/articles")
  end
end
