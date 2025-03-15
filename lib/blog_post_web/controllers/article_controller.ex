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
    user = conn.assigns.current_user
    changeset = Blog.change_article(%Article{})

    if Blog.can_do_action?(user, :create) do
      conn |> render(:new, changeset: changeset)
    else
      conn |> make_unauthorized("Unauthorized to create articles")
    end
  end

  def create(conn, %{"article" => article_params}) do
    user = conn.assigns.current_user

    if Blog.can_do_action?(user, :create) do
      case Blog.create_article(article_params) do
        {:ok, article} ->
          conn
          |> put_flash(:info, "Article created successfully.")
          |> redirect(to: ~p"/articles/#{article}")

        {:error, %Ecto.Changeset{} = changeset} ->
          render(conn, :new, changeset: changeset)
      end
    else
      conn |> make_unauthorized("Unauthorized to create articles")
    end
  end

  def show(conn, %{"id" => id}) do
    article = Blog.get_article!(id)
    render(conn, :show, article: article)
  end

  def edit(conn, %{"id" => id}) do
    user = conn.assigns.current_user
    article = Blog.get_article!(id)
    changeset = Blog.change_article(article)

    if Blog.can_do_action?(user, article, :update),
      do: conn |> render(:edit, article: article, changeset: changeset),
      else: conn |> make_unauthorized("Unauthorized to edit this post ")
  end

  def update(conn, %{"id" => id, "article" => article_params}) do
    article = Blog.get_article!(id)
    user = conn.assigns.current_user

    if Blog.can_do_action?(user, article, :update) do
      case Blog.update_article(article, article_params) do
        {:ok, article} ->
          conn
          |> put_flash(:info, "Article updated successfully.")
          |> redirect(to: ~p"/articles/#{article}")

        {:error, %Ecto.Changeset{} = changeset} ->
          render(conn, :edit, article: article, changeset: changeset)
      end
    else
      conn |> make_unauthorized("Unauthorized to edit this post ")
    end
  end

  def delete(conn, %{"id" => id}) do
    article = Blog.get_article!(id)
    user = conn.assigns.current_user

    if Blog.can_do_action?(user, article, :delete) do
      {:ok, _article} = Blog.delete_article(article)

      conn
      |> put_flash(:info, "Article deleted successfully.")
      |> redirect(to: ~p"/articles")
    else
      conn |> make_unauthorized("Unauthorized to delete this post")
    end
  end

  defp make_unauthorized(conn) do
    conn
    |> put_flash(:error, "You do not have permission to visit this site")
    |> redirect(to: ~p"/articles")
    |> halt()
  end

  defp make_unauthorized(conn, message) do
    conn
    |> put_flash(:error, message)
    |> redirect(to: ~p"/articles")
    |> halt()
  end
end
