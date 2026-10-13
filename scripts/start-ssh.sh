
#!/bin/sh
set -eu

KEY_DIR="/ssh-host-keys"
HOST_KEY="${KEY_DIR}/ssh_host_ed25519_key"

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

# Prepare SSH runtime directories.
mkdir -p /run/sshd "$KEY_DIR"
chmod 755 /run/sshd
chmod 700 "$KEY_DIR"

# Generate a persistent host key if one does not exist.
if [ ! -f "$HOST_KEY" ]; then
    log "Generating ED25519 SSH host key..."
    ssh-keygen -q -t ed25519 -N "" -f "$HOST_KEY"
fi

chmod 600 "$HOST_KEY"

if [ -f "${HOST_KEY}.pub" ]; then
    chmod 644 "${HOST_KEY}.pub"
fi

# Validate SSH configuration.
log "Validating SSH configuration..."
/usr/sbin/sshd -t -h "$HOST_KEY"

# Start the SSH server.
log "Starting OpenSSH server..."
exec /usr/sbin/sshd -D -e -h "$HOST_KEY"
