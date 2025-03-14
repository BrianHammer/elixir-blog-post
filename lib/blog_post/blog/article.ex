defmodule BlogPost.Blog.Article do
  use Ecto.Schema
  import Ecto.Changeset

  schema "articles" do
    field :title, :string
    field :image_url, :string
    field :content, :string

    belongs_to :user, BlogPost.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(article, attrs) do
    article
    |> cast(attrs, [:title, :image_url, :content, :user_id])
    |> validate_required([:title, :image_url, :content, :user_id])
    |> validate_length(:title, min: 5, max: 100)
    |> validate_length(:content, min: 10)
    |> assoc_constraint(:user)
  end
end
