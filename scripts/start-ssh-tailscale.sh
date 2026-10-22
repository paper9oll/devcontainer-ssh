#!/bin/sh
set -eu

KEY_DIR="/ssh-host-keys"
HOST_KEY="${KEY_DIR}/ssh_host_ed25519_key"
STATE_DIR="/var/lib/tailscale"
SOCKET="/run/tailscale/tailscaled.sock"

log() {
    printf '[devcontainer-ssh] %s\n' "$1"
}

# Require a password at startup.
if [ -z "${SSH_PASSWORD:-}" ]; then
    log "ERROR: SSH_PASSWORD is not configured."
    exit 1
fi

# Configure the existing vscode user's password.
printf 'vscode:%s\n' "$SSH_PASSWORD" | chpasswd
unset SSH_PASSWORD

# Prepare SSH and Tailscale runtime directories.
mkdir -p /run/sshd /run/tailscale "$KEY_DIR" "$STATE_DIR"
chmod 755 /run/sshd
chmod 700 "$KEY_DIR" "$STATE_DIR"

# Generate a persistent OpenSSH host key if one does not exist.
if [ ! -f "$HOST_KEY" ]; then
    log "Generating ED25519 SSH host key..."
    ssh-keygen -q -t ed25519 -N "" -f "$HOST_KEY"
fi
chmod 600 "$HOST_KEY"
if [ -f "${HOST_KEY}.pub" ]; then
    chmod 644 "${HOST_KEY}.pub"
fi

# Start Tailscale in userspace networking mode.
log "Starting Tailscale..."
tailscaled \
    --tun=userspace-networking \
    --statedir="$STATE_DIR" \
    --socket="$SOCKET" &
TAILSCALED_PID=$!
SSHD_PID=

cleanup() {
    if [ -n "$SSHD_PID" ]; then
        kill "$SSHD_PID" 2>/dev/null || true
        wait "$SSHD_PID" 2>/dev/null || true
    fi
    kill "$TAILSCALED_PID" 2>/dev/null || true
    wait "$TAILSCALED_PID" 2>/dev/null || true
}
trap cleanup EXIT
trap 'exit 0' INT TERM

# Wait for the Tailscale local API socket.
attempt=0
until [ -S "$SOCKET" ]; do
    attempt=$((attempt + 1))
    if [ "$attempt" -ge 30 ]; then
        log "ERROR: Tailscale did not become ready."
        exit 1
    fi
    sleep 1
done

# Authenticate a new node or enable SSH on its existing Tailscale identity.
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

# Validate SSH configuration.
log "Validating OpenSSH configuration..."
/usr/sbin/sshd -t -h "$HOST_KEY"

# Start the OpenSSH server.
log "Starting OpenSSH server..."
/usr/sbin/sshd -D -e -h "$HOST_KEY" &
SSHD_PID=$!
wait "$SSHD_PID"
