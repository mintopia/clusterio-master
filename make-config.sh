#!/bin/bash
export CONFIG_ERRORS=0

function error()
{
	echo "$1" >&2
	CONFIG_ERRORS=1
}

function ensure_int()
{
	if echo "$2" | egrep -qv '^[0-9]+$'
	then
		error "$1 must be an integer"
	fi
}

function ensure_int_range()
{
	v=$[$2]
	if [ $v -lt $3 ] || [ $v -gt $4 ]
	then
		error "$1 must be between ${3}-${4}"
	fi
}

function ensure_bool()
{
	if [ "$2" != "true" ] && [ "$2" != "false" ]
	then
		error "$1 must be either \"true\" or \"false\""
	fi
}

# Set default values for substitution
export CLUSTERIO_MODE="${CLUSTERIO_MODE:-client}"
export FACTORIO_USERNAME="${FACTORIO_USERNAME:-}"
export FACTORIO_TOKEN="${FACTORIO_TOKEN:-}"
export FACTORIO_TOKEN_FILE="${FACTORIO_TOKEN_FILE:-}"
export FACTORIO_PUBLIC_IP="${FACTORIO_PUBLIC_IP:-localhost}"
export FACTORIO_MASTER_IP="${FACTORIO_MASTER_IP:-localhost}"
export FACTORIO_MASTER_PORT="${FACTORIO_MASTER_PORT:-8080}"
export FACTORIO_MASTER_SSL_PORT="${FACTORIO_MASTER_SSL_PORT:-0}"
export FACTORIO_MASTER_AUTH_TOKEN="${FACTORIO_MASTER_AUTH_TOKEN:-}"
export FACTORIO_MASTER_AUTH_TOKEN_FILE="${FACTORIO_MASTER_AUTH_TOKEN_FILE:-}"
export FACTORIO_MASTER_AUTH_SECRET="${FACTORIO_MASTER_AUTH_SECRET:-}"
export FACTORIO_MASTER_AUTH_SECRET_FILE="${FACTORIO_MASTER_AUTH_SECRET_FILE:-}"
export FACTORIO_VERIFY_USER_IDENTITY="${FACTORIO_VERIFY_USER_IDENTITY:-false}"
export FACTORIO_USERNAME="${FACTORIO_USERNAME:-}"
export FACTORIO_TOKEN="${FACTORIO_TOKEN:-}"
export FACTORIO_VERSION="${FACTORIO_VERSION:-0.16}"
export FACTORIO_VISIBILITY_PUBLIC="${FACTORIO_VISIBILITY_PUBLIC:-true}"
export FACTORIO_VISIBILITY_LAN="${FACTORIO_VISIBILITY_LAN:-true}"
export FACTORIO_ALLOW_REMOTE_COMMAND_EXECUTION="${FACTORIO_ALLOW_REMOTE_COMMAND_EXECUTION:-true}"
export FACTORIO_ENABLE_CROSS_SERVER_SHOUT="${FACTORIO_ENABLE_CROSS_SERVER_SHOUT:-true}"
export FACTORIO_MIRROR_ALL_CHAT="${FACTORIO_MIRROR_ALL_CHAT:-false}"

# Load sensitive values from files
if [ ! -z "$FACTORIO_MASTER_AUTH_SECRET_FILE" ]
then
	if [ ! -f "$FACTORIO_MASTER_AUTH_SECRET_FILE" ]
	then
		error "FACTORIO_MASTER_AUTH_SECRET_FILE specified, but does not exist: $FACTORIO_MASTER_AUTH_SECRET_FILE"
	else
		echo "Loading FACTORIO_MASTER_AUTH_SECRET from $FACTORIO_MASTER_AUTH_SECRET_FILE"
		export FACTORIO_MASTER_AUTH_SECRET="$(cat "$FACTORIO_MASTER_AUTH_SECRET_FILE")"
		unset FACTORIO_MASTER_AUTH_SECRET_FILE
	fi
fi

if [ ! -z "$FACTORIO_MASTER_AUTH_TOKEN_FILE" ]
then
	if [ ! -f "$FACTORIO_MASTER_AUTH_TOKEN_FILE" ]
	then
		error "FACTORIO_MASTER_AUTH_TOKEN_FILE specified, but does not exist: $FACTORIO_MASTER_AUTH_TOKEN_FILE"
	else
		echo "Loading FACTORIO_MASTER_AUTH_TOKEN from $FACTORIO_MASTER_AUTH_TOKEN_FILE"
		export FACTORIO_MASTER_AUTH_TOKEN="$(cat "$FACTORIO_MASTER_AUTH_TOKEN_FILE")"
		unset FACTORIO_MASTER_AUTH_TOKEN_FILE
	fi
fi

if [ ! -z "$FACTORIO_TOKEN_FILE" ]
then
	if [ ! -f "$FACTORIO_TOKEN_FILE" ]
	then
		error "FACTORIO_TOKEN_FILE specified, but does not exist: $FACTORIO_TOKEN_FILE"
	else
		echo "Loading FACTORIO_TOKEN from $FACTORIO_TOKEN_FILE"
		export FACTORIO_TOKEN="$(cat "$FACTORIO_TOKEN_FILE")"
		unset FACTORIO_TOKEN_FILE
	fi
fi

# Check config values
if [ "$CLUSTERIO_MODE" != "client" ] && [ "$CLUSTERIO_MODE" != "master" ]
then
	error "Invalid mode $CLUSTERIO_MODE - must be either client or master"
fi

if [ -z "$FACTORIO_MASTER_AUTH_SECRET" ] && [ "$CLUSTERIO_MODE" == "master" ]
then
	error "Cannot run in master mode without FACTORIO_MASTER_AUTH_SECRET"
	error "Generate one with this command:"
	error "dd if=/dev/urandom bs=256 count=1 | base64 -w0 | sed 's/\+/-/g; s/\//_/g; s/=//g' >> master-auth-secret"
fi

if [ -z "$FACTORIO_MASTER_AUTH_TOKEN" ] && [ "$CLUSTERIO_MODE" == "client" ]
then
	error "Cannot run in client mode without FACTORIO_MASTER_AUTH_TOKEN or FACTORIO_MASTER_AUTH_TOKEN_FILE"
elif [ ! -z "$FACTORIO_MASTER_AUTH_TOKEN" ] && [ "$CLUSTERIO_MODE" == "master" ]
then
	# Avoid regenerating the auth token if we already have one
	echo -n "$FACTORIO_MASTER_AUTH_TOKEN" > secret-api-token.txt
fi

if [ "$FACTORIO_MASTER_SSL_PORT" != "0" ]
then
	if [ "$FACTORIO_MASTER_SSL_CERTIFICATE_FILE" == "" ] || [ "$FACTORIO_MASTER_SSL_KEY_FILE" == "" ]
	then
		error "Cannot listen on HTTPS port $FACTORIO_MASTER_SSL_PORT without FACTORIO_MASTER_SSL_CERTIFICATE_FILE and FACTORIO_MASTER_SSL_KEY_FILE"
	fi
fi

ensure_int_range "FACTORIO_MASTER_PORT" "$FACTORIO_MASTER_PORT" 80 65535
ensure_int_range "FACTORIO_MASTER_SSL_PORT" "$FACTORIO_MASTER_PORT" 80 65535
ensure_bool "FACTORIO_VERIFY_USER_IDENTITY" "$FACTORIO_VERIFY_USER_IDENTITY"
ensure_bool "FACTORIO_VISIBILITY_PUBLIC" "$FACTORIO_VISIBILITY_PUBLIC"
ensure_bool "FACTORIO_VISIBILITY_LAN" "$FACTORIO_VISIBILITY_LAN"
ensure_bool "FACTORIO_ALLOW_REMOTE_COMMAND_EXECUTION" "$FACTORIO_ALLOW_REMOTE_COMMAND_EXECUTION"
ensure_bool "FACTORIO_ENABLE_CROSS_SERVER_SHOUT" $FACTORIO_ENABLE_CROSS_SERVER_SHOUT
ensure_bool "FACTORIO_MIRROR_ALL_CHAT" $FACTORIO_MIRROR_ALL_CHAT

if [ "$CONFIG_ERRORS" == "1" ]
then
	exit -1
fi

envsubst < config.json.tmpl > config.json
