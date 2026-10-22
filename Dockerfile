# Unofficial SSH-enabled extension of Microsoft's Dev Containers
# Upstream: https://github.com/devcontainers/images

FROM mcr.microsoft.com/devcontainers/base:trixie AS base

USER root

LABEL org.opencontainers.image.title="Dev Container SSH" \
      org.opencontainers.image.description="Microsoft Debian Dev Container with optional OpenSSH and Tailscale SSH" \
      org.opencontainers.image.vendor="Community"

# Install OpenSSH and Tailscale so either service can be selected at runtime.
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        openssh-server \
    && curl -fsSL https://tailscale.com/install.sh | sh \
    && apt-get purge -y --auto-remove curl \
    && rm -rf /var/lib/apt/lists/*

# Prepare SSH runtime and workspace directories.
RUN mkdir -p \
        /run/sshd \
        /ssh-host-keys \
        /workspaces \
    && chown vscode:vscode /workspaces \
    && chmod 755 /run/sshd

# Configure OpenSSH.
RUN printf '%s\n' \
    'Port 22' \
    'PermitRootLogin no' \
    'PasswordAuthentication yes' \
    'PermitEmptyPasswords no' \
    'KbdInteractiveAuthentication no' \
    'UsePAM yes' \
    'PubkeyAuthentication yes' \
    'AllowUsers vscode' \
    'AllowTcpForwarding yes' \
    'X11Forwarding no' \
    > /etc/ssh/sshd_config.d/00-devcontainer-ssh.conf

COPY scripts/start-ssh.sh /usr/local/bin/start-ssh
RUN chmod 755 /usr/local/bin/start-ssh

WORKDIR /workspaces
EXPOSE 22
VOLUME ["/var/lib/tailscale"]
STOPSIGNAL SIGTERM
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 CMD if [ "${ENABLE_OPENSSH:-true}" = "true" ]; then bash -c ':</dev/tcp/127.0.0.1/22' || exit 1; fi; if [ "${ENABLE_TAILSCALED:-false}" = "true" ]; then tailscale --socket=/run/tailscale/tailscaled.sock status >/dev/null 2>&1 || exit 1; fi; exit 0
CMD ["/usr/local/bin/start-ssh"]

# Tailscale SSH variant
FROM base AS tailscale
USER root
RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl \
    && curl -fsSL https://tailscale.com/install.sh | sh \
    && apt-get purge -y --auto-remove curl \
    && rm -rf /var/lib/apt/lists/*

COPY scripts/start-ssh-tailscale.sh /usr/local/bin/start-ssh-tailscale
RUN chmod 755 /usr/local/bin/start-ssh-tailscale

VOLUME ["/var/lib/tailscale"]
CMD ["/usr/local/bin/start-ssh-tailscale"]
