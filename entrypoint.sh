#!/bin/sh
set -e

# Log function for consistent output
log() {
  echo "[entrypoint] $1"
}

# Error function for consistent error handling
error_exit() {
  echo "[entrypoint] ERROR: $1" >&2
  exit 1
}

# Validate required environment variables
validate_env() {
  local var_name="$1"
  local var_value="${!var_name}"
  if [ -z "$var_value" ]; then
    error_exit "Required environment variable $var_name is not set"
  fi
  log "$var_name is set"
}

# Increase file descriptor limit if permitted by the host microVM
log "Setting file descriptor limits..."
if ! ulimit -n 65536 2>/dev/null; then
  log "Warning: Could not set ulimit to 65536, trying 4096"
  if ! ulimit -n 4096 2>/dev/null; then
    log "Warning: Could not set ulimit to 4096, continuing with default"
    current_limit=$(ulimit -n 2>/dev/null || echo "unknown")
    log "Current file descriptor limit: $current_limit"
  else
    log "Successfully set ulimit to 4096"
  fi
else
  log "Successfully set ulimit to 65536"
fi

# Preload graceful-fs via Node options to prevent EMFILE crash on concurrent frontend chunk reads
if [ -f "/entrypoint-fs-patch.js" ]; then
  log "Loading graceful-fs patch"
  export NODE_OPTIONS="--require /entrypoint-fs-patch.js ${NODE_OPTIONS}"
else
  log "Warning: /entrypoint-fs-patch.js not found, graceful-fs patch may not work"
fi

# Dynamically map Vercel's runtime PORT to N8N_PORT
log "Configuring ports..."
if [ -n "$PORT" ] && [ "$PORT" -eq "$PORT" ] 2>/dev/null; then
  export N8N_PORT="$PORT"
  log "Mapped Vercel PORT ($PORT) to N8N_PORT"
elif [ -n "$N8N_PORT" ] && [ "$N8N_PORT" -eq "$N8N_PORT" ] 2>/dev/null; then
  log "Using explicit N8N_PORT: $N8N_PORT"
else
  export N8N_PORT=5678
  log "Using default N8N_PORT: 5678"
fi

# Enable Postgres only when USE_POSTGRES is explicitly true
log "Configuring database..."
if [ "$USE_POSTGRES" = "true" ]; then
  export DB_TYPE=postgresdb
  log "Using Postgres database"
  
  # Validate Postgres configuration when USE_POSTGRES is enabled
  validate_env "DB_POSTGRESDB_HOST" "$DB_POSTGRESDB_HOST"
  validate_env "DB_POSTGRESDB_DATABASE" "$DB_POSTGRESDB_DATABASE"
  validate_env "DB_POSTGRESDB_USER" "$DB_POSTGRESDB_USER"
  validate_env "DB_POSTGRESDB_PASSWORD" "$DB_POSTGRESDB_PASSWORD"
  
  # Set default port if not specified
  if [ -z "$DB_POSTGRESDB_PORT" ]; then
    export DB_POSTGRESDB_PORT=5432
    log "Using default Postgres port: 5432"
  fi
else
  export DB_TYPE=sqlite
  log "Using SQLite database (default)"
  # Clean up Postgres env vars when not in use
  unset DB_POSTGRESDB_DATABASE DB_POSTGRESDB_HOST DB_POSTGRESDB_PORT DB_POSTGRESDB_USER DB_POSTGRESDB_PASSWORD
fi

# Fallback WEBHOOK_URL if not provided
if [ -z "$WEBHOOK_URL" ]; then
  export WEBHOOK_URL="https://n8n-vercel-alpha.vercel.app"
  log "Using fallback WEBHOOK_URL: $WEBHOOK_URL"
else
  log "Using configured WEBHOOK_URL: $WEBHOOK_URL"
fi

# Final validation check
log "Configuration summary:"
log "  N8N_PORT: $N8N_PORT"
log "  DB_TYPE: $DB_TYPE"
log "  WEBHOOK_URL: $WEBHOOK_URL"
log "  USE_POSTGRES: ${USE_POSTGRES:-false}"
log "Starting n8n..."

# Dispatch command arguments cleanly
if [ "$#" -eq 0 ] || [ "$1" = "start" ]; then
  log "Executing: /docker-entrypoint.sh start"
  exec /docker-entrypoint.sh start
elif [ "$1" = "n8n" ]; then
  shift
  log "Executing: /docker-entrypoint.sh $@"
  exec /docker-entrypoint.sh "$@"
elif [ "$1" = "/bin/sh" ] || [ "$1" = "sh" ]; then
  if [ "$2" = "-c" ] && [ -n "$3" ]; then
    log "Executing shell command: $3"
    exec "$@"
  else
    log "Executing: /docker-entrypoint.sh start"
    exec /docker-entrypoint.sh start
  fi
elif [ "$1" = "/usr/local/bin/node" ] || [ "$1" = "node" ]; then
  if [ "$2" = "/usr/local/bin/n8n" ] || [ "$2" = "n8n" ]; then
    shift 2
    log "Executing: /docker-entrypoint.sh $@"
    exec /docker-entrypoint.sh "$@"
  else
    log "Executing: $@"
    exec "$@"
  fi
else
  log "Executing: /docker-entrypoint.sh $@"
  exec /docker-entrypoint.sh "$@"
fi
