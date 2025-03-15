defmodule BlogPostWeb.Plugs.RequireArticlePermission do
  use Phoenix.VerifiedRoutes,
    router: BlogPostWeb.Router,
    endpoint: BlogPostWeb.Endpoint,
    statics: ~w(images)

  import Plug.Conn
  import Phoenix.Controller
  alias BlogPost.Blog

  def init(action), do: action

  # NEw call
  def call(%{private: %{phoenix_action: action}} = conn, _opts)
      when action in [:create, :update, :delete] do
    user = conn.assigns.current_user
    authorized? = conn |> is_authorized?(user, action)

    conn
    |> conn_redirect_if_false(authorized?)
  end

  def call(conn, _opts), do: conn

  defp is_authorized?(_conn, user, action = :create) do
    Blog.can_do_action?(user, action)
  end

  defp is_authorized?(conn, user, action) when action in [:update, :delete] do
    article = fetch_article(conn)
    Blog.can_do_action?(user, article, action)
  end

  defp fetch_article(conn) do
    case conn.path_info do
      ["articles", id] -> Blog.get_article!(id)
      _ -> nil
    end
  end

  defp conn_redirect_if_false(conn, bool) do
    case bool do
      true ->
        conn

      false ->
        conn
        |> put_flash(:error, "You are not authorized to perform this action")
        |> redirect(to: ~p"/articles")
        |> halt()
    end
  end
end
