
# Unofficial SSH-enabled extension of Microsoft Dev Containers.
# Upstream: https://github.com/devcontainers/images

FROM mcr.microsoft.com/devcontainers/base:trixie

USER root

LABEL org.opencontainers.image.title="Dev Container SSH" \
      org.opencontainers.image.description="Microsoft Debian Dev Container with OpenSSH support" \
      org.opencontainers.image.vendor="Community"

# Install OpenSSH
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        openssh-server \
    && rm -rf /var/lib/apt/lists/*

# Prepare SSH
RUN mkdir -p \
        /run/sshd \
        /ssh-host-keys \
        /workspaces \
    && chown vscode:vscode /workspaces \
    && chmod 755 /run/sshd

# Configure SSH
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

STOPSIGNAL SIGTERM

CMD ["/usr/local/bin/start-ssh"]
