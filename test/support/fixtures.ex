defmodule Integrate.Fixtures do
  @moduledoc """
  Test fixtures.
  """
  use Integrate, :contexts

  def create_user(_) do
    attrs = %{
      username: "root",
      password: "1234567890"
    }
    {:ok, user} = Accounts.create_user(attrs)

    %{user: user}
  end

  def create_stakeholder(%{user: user}) do
    attrs = %{
      name: "reporter",
      user_id: user.id
    }
    {:ok, stakeholder} = Stakeholders.create_stakeholder(attrs)

    %{stakeholder: stakeholder}
  end
end
