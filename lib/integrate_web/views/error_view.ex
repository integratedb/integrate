defmodule IntegrateWeb.ErrorView do
  use IntegrateWeb, :view

  # If you want to customize a particular status code
  # for a certain format, you may uncomment below.
  def render("500.json", _assigns) do
    %{errors: %{detail: "Internal Server Error"}}
  end

  def render("422.json", %{errors: errors}) do
    %{errors: %{detail: Enum.map(errors, &format_error/1)}}
  end

  defp format_error(err) when is_tuple(err) do
    Tuple.to_list(err)
  end

  defp format_error(err), do: err

  # By default, Phoenix returns the status message from
  # the template name. For example, "404.json" becomes
  # "Not Found".
  def template_not_found(template, _assigns) do
    %{errors: %{detail: Phoenix.Controller.status_message_from_template(template)}}
  end
end
