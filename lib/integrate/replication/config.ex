defmodule Integrate.Replication.Config do
  @moduledoc """
  Allows Integrate to "just work" with a `DATABASE_URL` -- reusing postgrex
  based repo database connection config for the epgsql connection underpinning
  the replication capability.

  Note that this fragile coersion magic can be avoided by explicitly passing
  an `epgsql: [host: 'lala', ...]` section in your `Integrate.Replication` config.
  """

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

  def merge(opts) do
    {url, config} =
      :integrate
      |> Application.fetch_env!(Integrate.Repo)
      |> Keyword.take(@connection_keys)
      |> Keyword.merge(opts)
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
    |> Map.put(:replication, 'database')
  end
end