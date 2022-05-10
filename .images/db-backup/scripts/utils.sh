#!/bin/bash

## Docker Secrets Support
## usage: file_env VAR [DEFAULT]
##    ie: file_env 'XYZ_DB_PASSWORD' 'example'
##        (will allow for "$XYZ_DB_PASSWORD_FILE" to fill in the value of "$XYZ_DB_PASSWORD" from a file, especially for Docker's secrets feature)
file_env() {
    local var="$1"
    local fileVar="${var}_FILE"
    local def="${2:-}"
    local val="$def"

    if [ "${!fileVar:-}" ]; then
        val="$(cat "${!fileVar}")"
    elif [ "${!var:-}" ]; then
        val="${!var}"
    fi

    if [ -z "${val}" ]; then
        print_error "error: neither $var nor $fileVar are set but are required"
        exit 1
    fi

    export "$var"="$val"
    unset "$fileVar"
}

## An attempt to shut down so much noise in the log files, specifically for echo statements
output_off() {
    if [ "${DEBUG_MODE,,}" = "true" ] ; then
        set +x
    fi
}

output_on() {
    if [ "${DEBUG_MODE,,}" = "true" ] ; then
        set -x
    fi
}

print_info() {
    output_off
    echo -e "[INFO] $1"
    output_on
}

print_debug() {
    output_off
    case "$CONTAINER_LOG_LEVEL" in
            "DEBUG" )
                echo -e "[DEBUG] $1"
            ;;
    esac
    output_on
}

print_notice() {
    output_off
    case "$CONTAINER_LOG_LEVEL" in
            "DEBUG" | "NOTICE" )
                echo -e "[NOTICE] $1"
            ;;
    esac
    output_on
}

print_warn() {
    output_off
    case "$CONTAINER_LOG_LEVEL" in
            "DEBUG" | "NOTICE" | "WARN")
                echo -e "[WARN] $1"
            ;;
    esac
    output_on
}

print_error() {
    output_off
    case "$CONTAINER_LOG_LEVEL" in
            "DEBUG" | "NOTICE" | "WARN" | "ERROR")
                echo -e "[ERROR] $1"
            ;;
    esac
    output_on
}

## Check is Variable is Defined
## Usage: sanity_var varname "Description"
sanity_var() {
    print_debug "Looking for existence of $1 environment variable"
    if [ ! -v "$1" ]; then
        print_error "No '$2' Entered! - Set '\$$1'"
        exit 1
    fi
}
