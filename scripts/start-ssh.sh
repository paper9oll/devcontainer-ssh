#!/bin/sh
set -eu

KEY_DIR="/ssh-host-keys"
HOST_KEY="${KEY_DIR}/ssh_host_ed25519_key"
STATE_DIR="/var/lib/tailscale"
SOCKET="/run/tailscale/tailscaled.sock"
ENABLE_OPENSSH="${ENABLE_OPENSSH:-true}"
ENABLE_TAILSCALED="${ENABLE_TAILSCALED:-false}"
SSHD_PID=
TAILSCALED_PID=

log() {
    printf '[devcontainer-ssh] %s\n' "$1"
}

validate_bool() {
    case "$2" in
        true|false) ;;
        *)
            log "ERROR: $1 must be 'true' or 'false'."
            exit 1
            ;;
    esac
}

validate_bool ENABLE_OPENSSH "$ENABLE_OPENSSH"
validate_bool ENABLE_TAILSCALED "$ENABLE_TAILSCALED"

if [ "$ENABLE_OPENSSH" = "true" ]; then
    if [ -z "${SSH_PASSWORD:-}" ]; then
        log "ERROR: SSH_PASSWORD is required when OpenSSH is enabled."
        exit 1
    fi

    printf 'vscode:%s\n' "$SSH_PASSWORD" | chpasswd
    unset SSH_PASSWORD

    mkdir -p /run/sshd "$KEY_DIR"
    chmod 755 /run/sshd
    chmod 700 "$KEY_DIR"

    if [ ! -f "$HOST_KEY" ]; then
        log "Generating ED25519 SSH host key..."
        ssh-keygen -q -t ed25519 -N "" -f "$HOST_KEY"
    fi
    chmod 600 "$HOST_KEY"
    if [ -f "${HOST_KEY}.pub" ]; then
        chmod 644 "${HOST_KEY}.pub"
    fi

    log "Validating OpenSSH configuration..."
    /usr/sbin/sshd -t -h "$HOST_KEY"
fi

cleanup() {
    if [ -n "$SSHD_PID" ]; then
        kill "$SSHD_PID" 2>/dev/null || true
        wait "$SSHD_PID" 2>/dev/null || true
    fi
    if [ -n "$TAILSCALED_PID" ]; then
        kill "$TAILSCALED_PID" 2>/dev/null || true
        wait "$TAILSCALED_PID" 2>/dev/null || true
    fi
}
trap cleanup EXIT
trap 'exit 0' INT TERM

if [ "$ENABLE_TAILSCALED" = "true" ]; then
    mkdir -p "$STATE_DIR" /run/tailscale
    chmod 700 "$STATE_DIR"

    log "Starting Tailscale..."
    tailscaled \
        --tun=userspace-networking \
        --statedir="$STATE_DIR" \
        --socket="$SOCKET" &
    TAILSCALED_PID=$!

    attempt=0
    until [ -S "$SOCKET" ]; do
        attempt=$((attempt + 1))
        if [ "$attempt" -ge 30 ]; then
            log "ERROR: Tailscale did not become ready."
            exit 1
        fi
        sleep 1
    done

    if ! tailscale --socket="$SOCKET" status >/dev/null 2>&1; then
        if [ -z "${TS_AUTHKEY:-}" ]; then
            log "ERROR: TS_AUTHKEY is required for initial Tailscale authentication."
            exit 1
        fi
        log "Authenticating Tailscale node and enabling Tailscale SSH..."
        tailscale --socket="$SOCKET" up \
            --authkey="$TS_AUTHKEY" \
            --ssh \
            --accept-dns=false \
            --hostname="${TS_HOSTNAME:-devcontainer-ssh}"
        unset TS_AUTHKEY
    else
        log "Enabling Tailscale SSH for the existing node..."
        tailscale --socket="$SOCKET" set --ssh
    fi
fi

if [ "$ENABLE_OPENSSH" = "true" ]; then
    log "Starting OpenSSH server..."
    /usr/sbin/sshd -D -e -h "$HOST_KEY" &
    SSHD_PID=$!
fi

if [ -n "$SSHD_PID" ]; then
    wait "$SSHD_PID"
elif [ -n "$TAILSCALED_PID" ]; then
    wait "$TAILSCALED_PID"
else
    log "OpenSSH and Tailscale are disabled; keeping the container available for docker exec."
    exec sleep infinity
fi
