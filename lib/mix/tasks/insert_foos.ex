defmodule Mix.Tasks.InsertFoos do
  use Mix.Task

  alias Integrate.Foo
  alias Integrate.Repo

  @default_delay_secs 5

  @shortdoc "Insert a foo every `delay` seconds."
  def run(args) do
    Logger.configure(level: :warning)

    [:postgrex, :ecto] |> Enum.each(&Application.ensure_all_started/1)
    {:ok, _} = Repo.start_link

    delay_secs =
      case args do
        [arg] -> String.to_integer(arg)
        _alt -> @default_delay_secs
      end

    IO.puts("Looping every #{delay_secs} seconds.")
    loop({1, delay_secs * 1000})
  end

  defp loop({counter, delay_ms}) do
    insert_foo(counter)

    Process.sleep(delay_ms)

    loop({counter + 1, delay_ms})
  end

  defp insert_foo(counter) do
    name = "#{counter}-#{random_string(6)}"

    foo =
      %Foo{}
      |> Foo.changeset(%{name: name})
      |> Repo.insert!()

    IO.puts("- inserted foo id:#{foo.id} name:#{foo.name}")
  end

  defp random_string(len) do
    len / 2
    |> Kernel.trunc()
    |> :crypto.strong_rand_bytes()
    |> Base.encode16(case: :lower)
  end
end
