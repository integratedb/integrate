defmodule IntegrateWeb.FallbackController do
  @moduledoc """
  Translates controller action results into valid `Plug.Conn` responses.

  See `Phoenix.Controller.action_fallback/1` for more details.
  """
  use IntegrateWeb, :controller

  # This clause handles errors returned by Ecto's insert/update/delete.
  def call(conn, {:error, %Ecto.Changeset{} = changeset}) do
    conn
    |> put_status(:unprocessable_entity)
    |> put_view(IntegrateWeb.ChangesetView)
    |> render("error.json", changeset: changeset)
  end

  # These clauses handles errors returned by Ecto's multi.
  def call(conn, {:error, _key, %Ecto.Changeset{} = changeset, _changes_so_far}) do
    conn
    |> put_status(:unprocessable_entity)
    |> put_view(IntegrateWeb.ChangesetView)
    |> render("error.json", changeset: changeset)
  end

  def call(conn, {:error, _key, exception, _changes_so_far}) do
    IO.inspect(exception)

    conn
    |> put_status(:unprocessable_entity)
    |> put_view(IntegrateWeb.ErrorView)
    |> render(:"500")
  end

  # This clause is an example of how to handle resources that cannot be found.
  def call(conn, {:error, :not_found}) do
    conn
    |> put_status(:not_found)
    |> put_view(IntegrateWeb.ErrorView)
    |> render(:"404")
  end

  def call(conn, other) do
    IO.inspect({"XXX controller did not expect argument:", other})

    conn
    |> put_status(:internal_server_error)
    |> put_view(IntegrateWeb.ErrorView)
    |> render(:"500")
  end
end
