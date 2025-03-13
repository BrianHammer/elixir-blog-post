defmodule BlogPost.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  # %{key = action, value = the minimum value to perform an action}

  # permission rules:
  # 1. all users can delete and edit their own posts, profiles, etc.
  # 2. To create something requires at least the permission level listed below
  # 3. Editing and deleting requires permissions below
  # 4. Only one owner, and only the owner can change
  @permissions_table %{
    create_comment: 0,
    create_blog: 100,
    edit_blog: 200,
    delete_blog: 200,
    delete_comment: 200,
    delete_account: 200,
    change_user_roles: 300,
    change_owner: 300
  }

  @actions Map.keys(@permissions_table)

  schema "users" do
    field :email, :string
    field :password, :string, virtual: true, redact: true
    field :hashed_password, :string, redact: true
    field :current_password, :string, virtual: true, redact: true
    field :confirmed_at, :utc_datetime

    # Added
    field :permission_level, Ecto.Enum,
      values: [guest: 0, writer: 100, lead_writer: 105, admin: 200, owner: 300],
      default: :guest

    timestamps(type: :utc_datetime)
  end

  @doc """
  A user changeset for permission level.

  Permission levels may be inserted as an atom, string, or number.

  ## Examples

    # default value is set to "guest"
    iex> User.permission_level_changeset(%User{}) |> Map.get(:valid?)
    true

    # Setting permission to admin using the number value
    iex> User.permission_level_changeset(%User{}, %{permission_level: 100}) |> Map.get(:valid?)
    true

    # Accepts atoms
    iex> User.permission_level_changeset(%User{}, %{permission_level: :admin}) |> Map.get(:valid?)
    true

    # Accepts strings
    iex> User.permission_level_changeset(%User{}, %{permission_level: "admin"}) |> Map.get(:valid?)
    true

    # Rejects non enum values
    iex> User.permission_level_changeset(%User{}, %{permission_level: "blah blah"}) |> Map.get(:valid?)
    false
    iex> User.permission_level_changeset(%User{}, %{permission_level: :blah_blah}) |> Map.get(:valid?)
    false
    iex> User.permission_level_changeset(%User{}, %{permission_level: 6969}) |> Map.get(:valid?)
    false

  """

  def permission_level_changeset(user, attrs \\ %{}) do
    user
    |> cast(attrs, [:permission_level])
    |> validate_permission_level()
  end

  defp validate_permission_level(changeset) do
    changeset
    |> validate_inclusion(
      :permission_level,
      permission_level_values()
    )
  end

  defp permission_level_values(),
    do:
      Ecto.Enum.values(
        BlogPost.Accounts.User,
        :permission_level
      )

  @doc """
  Checks if the user has the rank to alter


  TODO ***************************8
  """

  # Gets if the user can perform an action based on the permission number and number table
  # defaults to false when there is an unknown action
  def acceptable_user_action?(user = %__MODULE__{}, action) when action in @actions,
    do: user |> get_user_permission_number() >= @permissions_table |> Map.get(action)
  def acceptable_user_action_for_level?(_user, _action), do: false

  defp get_permission_number(permission) do
    Ecto.Enum.mappings(__MODULE__, :permission_level)
    |> Keyword.get(permission)
  end

  defp get_user_permission_number(user) do
    user.permission_level |> get_permission_number()
  end

  def higher_or_equal_permission_number_than_user?(user = %__MODULE__{}, comparing_user = %__MODULE__{}),
    do: user |> get_user_permission_number() >= comparing_user |> get_user_permission_number()

  def has_higher_or_equal_permission_number?(user = %__MODULE__{}, permission_level) do
    user |> get_user_permission_number() >= permission_level |> get_permission_number()
  end

  @doc """
  A user changeset for registration.

  It is important to validate the length of both email and password.
  Otherwise databases may truncate the email without warnings, which
  could lead to unpredictable or insecure behaviour. Long passwords may
  also be very expensive to hash for certain algorithms.

  ## Options

    * `:hash_password` - Hashes the password so it can be stored securely
      in the database and ensures the password field is cleared to prevent
      leaks in the logs. If password hashing is not needed and clearing the
      password field is not desired (like when using this changeset for
      validations on a LiveView form), this option can be set to `false`.
      Defaults to `true`.

    * `:validate_email` - Validates the uniqueness of the email, in case
      you don't want to validate the uniqueness of the email (like when
      using this changeset for validations on a LiveView form before
      submitting the form), this option can be set to `false`.
      Defaults to `true`.
  """
  def registration_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:email, :password])
    |> validate_email(opts)
    |> validate_password(opts)
  end

  defp validate_email(changeset, opts) do
    changeset
    |> validate_required([:email])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must have the @ sign and no spaces")
    |> validate_length(:email, max: 160)
    |> maybe_validate_unique_email(opts)
  end

  defp validate_password(changeset, opts) do
    changeset
    |> validate_required([:password])
    |> validate_length(:password, min: 12, max: 72)
    # Examples of additional password validation:
    # |> validate_format(:password, ~r/[a-z]/, message: "at least one lower case character")
    # |> validate_format(:password, ~r/[A-Z]/, message: "at least one upper case character")
    # |> validate_format(:password, ~r/[!?@#$%^&*_0-9]/, message: "at least one digit or punctuation character")
    |> maybe_hash_password(opts)
  end

  defp maybe_hash_password(changeset, opts) do
    hash_password? = Keyword.get(opts, :hash_password, true)
    password = get_change(changeset, :password)

    if hash_password? && password && changeset.valid? do
      changeset
      # If using Bcrypt, then further validate it is at most 72 bytes long
      |> validate_length(:password, max: 72, count: :bytes)
      # Hashing could be done with `Ecto.Changeset.prepare_changes/2`, but that
      # would keep the database transaction open longer and hurt performance.
      |> put_change(:hashed_password, Bcrypt.hash_pwd_salt(password))
      |> delete_change(:password)
    else
      changeset
    end
  end

  defp maybe_validate_unique_email(changeset, opts) do
    if Keyword.get(opts, :validate_email, true) do
      changeset
      |> unsafe_validate_unique(:email, BlogPost.Repo)
      |> unique_constraint(:email)
    else
      changeset
    end
  end

  @doc """
  A user changeset for changing the email.

  It requires the email to change otherwise an error is added.
  """
  def email_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:email])
    |> validate_email(opts)
    |> case do
      %{changes: %{email: _}} = changeset -> changeset
      %{} = changeset -> add_error(changeset, :email, "did not change")
    end
  end

  @doc """
  A user changeset for changing the password.

  ## Options

    * `:hash_password` - Hashes the password so it can be stored securely
      in the database and ensures the password field is cleared to prevent
      leaks in the logs. If password hashing is not needed and clearing the
      password field is not desired (like when using this changeset for
      validations on a LiveView form), this option can be set to `false`.
      Defaults to `true`.
  """
  def password_changeset(user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:password])
    |> validate_confirmation(:password, message: "does not match password")
    |> validate_password(opts)
  end

  @doc """
  Confirms the account by setting `confirmed_at`.
  """
  def confirm_changeset(user) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)
    change(user, confirmed_at: now)
  end

  @doc """
  Verifies the password.

  If there is no user or the user doesn't have a password, we call
  `Bcrypt.no_user_verify/0` to avoid timing attacks.
  """
  def valid_password?(%BlogPost.Accounts.User{hashed_password: hashed_password}, password)
      when is_binary(hashed_password) and byte_size(password) > 0 do
    Bcrypt.verify_pass(password, hashed_password)
  end

  def valid_password?(_, _) do
    Bcrypt.no_user_verify()
    false
  end

  @doc """
  Validates the current password otherwise adds an error to the changeset.
  """
  def validate_current_password(changeset, password) do
    changeset = cast(changeset, %{current_password: password}, [:current_password])

    if valid_password?(changeset.data, password) do
      changeset
    else
      add_error(changeset, :current_password, "is not valid")
    end
  end
end
