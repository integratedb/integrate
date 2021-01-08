defmodule Integrate.Replication.Config do
  @moduledoc """
  Replication config helpers.
  """

  alias Integrate.Replication

  @namespace_exp ~r/^\w{1,64}$/

  @connection_keys [
    :url,
    :username,
    :password,
    :hostname,
    :port,
    :database,
    :ssl,
    :ssl_opts
  ]

  @doc """
  Allows `Integrate.Replication`'s epgsql connection to "just work" with the existing
  Repo database connection config (including a `DATABASE_URL`).

  This can be avoided by explicitly passing an `epgsql: [host: 'lala', ...]` section
  in your `Integrate.Replication` config.
  """
  def parse_repo_config_into_epgsql_config do
    {url, config} =
      :integrate
      |> Application.fetch_env!(Integrate.Repo)
      |> Keyword.take(@connection_keys)
      |> Keyword.pop(:url)

    config =
      case {config[:hostname], url} do
        {nil, nil} ->
          raise "Requires hostname or url to be configured."

        {nil, url} ->
          %URI{
            host: hostname,
            path: "/" <> database,
            port: port,
            query: query,
            userinfo: userinfo
          } = url

          opts = [
            hostname: hostname,
            port: port,
            database: database
          ]

          opts =
            case userinfo do
              nil ->
                opts

              value ->
                case String.split(value, ":") do
                  [username, password] ->
                    opts
                    |> Keyword.put(:username, username)
                    |> Keyword.put(:password, password)

                  [username] ->
                    opts
                    |> Keyword.put(:username, username)
                end
            end

          opts =
            case query do
              nil ->
                opts

              value ->
                case URI.decode_query(value) do
                  %{"ssl" => x} when x in ["true", "on"] ->
                    opts
                    |> Keyword.put(:ssl, true)

                  %{"ssl" => x} when x in ["false", "off"] ->
                    opts
                    |> Keyword.put(:ssl, false)

                  _ ->
                    opts
                end
            end

          config
          |> Keyword.merge(opts)

        _ ->
          config
      end

    config
    |> Enum.reject(fn {_, v} -> is_nil(v) end)
    |> Enum.map(fn {k, v} ->
      case is_binary(v) do
        true -> {k, String.to_charlist(v)}
        false -> {k, v}
      end
    end)
    |> Enum.map(fn {k, v} ->
      case k do
        :hostname -> {:host, v}
        _ -> {k, v}
      end
    end)
    |> Enum.into(%{})
  end

  def config do
    :integrate
    |> Application.get_env(Replication)
  end

  def producer do
    config()
    |> Keyword.get(:producer, Replication.Producer)
  end

  def epgsql do
    config()
    |> Keyword.get(:epgsql)
  end

  def publication_name do
    "#{escaped_namespace()}_publication"
  end

  def slot_name do
    "#{escaped_namespace()}_slot"
  end

  def escaped_namespace do
    config()
    |> Keyword.fetch!(:namespace)
    |> validate_and_downcase_namespace()
  end

  defp validate_and_downcase_namespace(value) when is_binary(value) do
    case String.match?(value, @namespace_exp) do
      true ->
        String.downcase(value)

      false ->
        raise "Invalid namespace -- must match `#{Regex.source(@namespace_exp)}`."
    end
  end
end
