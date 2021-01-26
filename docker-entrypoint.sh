#!/bin/sh

set -e
set -x

app=/app/bin/integratedb

if [ $1 = "up" ]; then
  $app eval "Integrate.Release.migrate"
  exec $app start
elif [ $1 = "migrate" ]; then
  exec $app eval "Integrate.Release.migrate"
elif [ $1 = "seed" ]; then
  exec $app eval "Integrate.Release.seed"
elif [ $1 = "rollback" ]; then
  exec $app eval "Integrate.Release.rollback($2)"
else
  exec $app $@
fi
