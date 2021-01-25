{ pkgs ? import <nixpkgs> {} }:

with pkgs;

let
  inherit (lib) optional optionals;

  elixir = beam.packages.erlangR23.elixir_1_11;
  postgres = postgresql_12;

  phoenixVersion = "1.5.7";
in

mkShell {
  buildInputs = [ elixir git glibcLocales postgres ]
    ++ optional stdenv.isLinux inotify-tools # For file_system on Linux.
    ++ optionals stdenv.isDarwin (with darwin.apple_sdk.frameworks; [
      # For file_system on macOS.
      CoreFoundation
      CoreServices
    ]);

  # Put the PostgreSQL databases in the project diretory.
  shellHook = ''
    export PGDATA="$PWD/.postgres"
    export PGHOST="$PGDATA/sockets"

    if [ ! -d "$PGHOST" ]
    then
      initdb --encoding=UTF-8 --auth-local trust --auth-host reject
      mkdir -p $PGHOST
    fi

    export MIX_ARCHIVES="$PWD/.mix/archives"
    if [ ! -d "$MIX_ARCHIVES" ]
    then
      mkdir -p $MIX_ARCHIVES

      LC_CTYPE=C.UTF-8 mix local.hex --force
      LC_CTYPE=C.UTF-8 mix archive.install --force hex phx_new ${phoenixVersion}
    fi
  '';
}
