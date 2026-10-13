
#!/bin/sh
set -eu

KEY_DIR="/ssh-host-keys"
HOST_KEY="${KEY_DIR}/ssh_host_ed25519_key"
AUTHORIZED_KEYS="/etc/ssh/authorized_keys"

log() {
    printf '[devcontainer-ssh] %s\n' "$1"
}

# Ensure SSH runtime directory exists
mkdir -p /run/sshd
chmod 755 /run/sshd

# Require authorized public keys
if [ ! -f "$AUTHORIZED_KEYS" ]; then
    log "ERROR: SSH authorized_keys file is missing."
    exit 1
fi

if [ ! -r "$AUTHORIZED_KEYS" ]; then
    log "ERROR: SSH authorized_keys file is not readable."
    exit 1
fi

if ! grep -Eq '^[[:space:]]*(ssh-ed25519|ssh-rsa|ecdsa-sha2-|sk-ssh-ed25519@|sk-ecdsa-sha2-)' "$AUTHORIZED_KEYS"; then
    log "ERROR: No supported SSH public key found."
    exit 1
fi

# Validate the persistent host-key directory
if [ ! -d "$KEY_DIR" ]; then
    log "ERROR: SSH host-key directory is missing."
    exit 1
fi

chmod 700 "$KEY_DIR"

# Generate a host key only on first startup
if [ ! -f "$HOST_KEY" ]; then
    log "Generating new ED25519 SSH host key..."
    ssh-keygen -q -t ed25519 -N "" -f "$HOST_KEY"
fi

chmod 600 "$HOST_KEY"
chmod 644 "${HOST_KEY}.pub"

# Validate the SSH server configuration
log "Validating SSH configuration..."
/usr/sbin/sshd -t -h "$HOST_KEY"

# Start SSH in the foreground
log "Starting OpenSSH server..."
exec /usr/sbin/sshd -D -e -h "$HOST_KEY"
