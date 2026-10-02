#!/bin/sh
set -e

# Increase file descriptor limit if permitted by the host microVM
ulimit -n 65536 2>/dev/null || ulimit -n 4096 2>/dev/null || true

# Preload graceful-fs via Node options to prevent EMFILE crash on concurrent frontend chunk reads
if [ -f "/entrypoint-fs-patch.js" ]; then
  export NODE_OPTIONS="--require /entrypoint-fs-patch.js ${NODE_OPTIONS}"
fi

# Dynamically map Vercel's runtime PORT to N8N_PORT
if [ -n "$PORT" ] && [ "$PORT" -eq "$PORT" ] 2>/dev/null; then
  export N8N_PORT="$PORT"
elif [ -z "$N8N_PORT" ] || ! [ "$N8N_PORT" -eq "$N8N_PORT" ] 2>/dev/null; then
  export N8N_PORT=5678
fi

# Automatically enable Postgres when credentials or flag are supplied
if [ "$USE_POSTGRES" = "true" ] || [ -n "$DB_POSTGRESDB_HOST" ]; then
  export DB_TYPE=postgresdb
else
  export DB_TYPE=sqlite
  unset DB_POSTGRESDB_DATABASE DB_POSTGRESDB_HOST DB_POSTGRESDB_PORT DB_POSTGRESDB_USER DB_POSTGRESDB_PASSWORD
fi

# Fallback WEBHOOK_URL if not provided
if [ -z "$WEBHOOK_URL" ]; then
  export WEBHOOK_URL="https://n8n-vercel-alpha.vercel.app"
fi

# Dispatch command arguments cleanly
if [ "$#" -eq 0 ]; then
  exec /docker-entrypoint.sh start
elif [ "$1" = "start" ]; then
  exec /docker-entrypoint.sh start
elif [ "$1" = "n8n" ]; then
  shift
  exec /docker-entrypoint.sh "$@"
elif [ "$1" = "/bin/sh" ] || [ "$1" = "sh" ]; then
  if [ "$2" = "-c" ] && [ -n "$3" ]; then
    exec "$@"
  else
    exec /docker-entrypoint.sh start
  fi
elif [ "$1" = "/usr/local/bin/node" ] || [ "$1" = "node" ]; then
  if [ "$2" = "/usr/local/bin/n8n" ] || [ "$2" = "n8n" ]; then
    shift 2
    exec /docker-entrypoint.sh "$@"
  else
    exec "$@"
  fi
else
  exec /docker-entrypoint.sh "$@"
fi
