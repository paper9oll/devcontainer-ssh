# devcontainer-ssh

An opinionated, SSH-enabled development environment based on [Microsoft's Dev Container image](https://github.com/devcontainers/images), designed for keeping projects inside the environment and accessing them remotely over SSH.

## Install

### 1. Download the required files

Create a directory of your choice (for example, `./devcontainer`) to hold `docker-compose.yml` and `.env`.

```sh
mkdir -p ./devcontainer
cd ./devcontainer
```

Download [docker-compose.yml](https://raw.githubusercontent.com/paper9oll/devcontainer-ssh/main/docker-compose.yml) and [.env.example](https://raw.githubusercontent.com/paper9oll/devcontainer-ssh/main/.env.example) by running:

```sh
curl -fsSL https://raw.githubusercontent.com/paper9oll/devcontainer-ssh/main/docker-compose.yml -o docker-compose.yml
```

```sh
curl -fsSL https://raw.githubusercontent.com/paper9oll/devcontainer-ssh/main/.env.example -o .env.example
cp .env.example .env
```

Alternatively, download those two files in your browser and move them to the directory you created. Then copy `.env.example` to `.env`.

### 2. Configure `.env` file

```env
# Enable OpenSSH
ENABLE_OPENSSH=true

# Port used to SSH into the container
SSH_PORT=2222

# Required when OpenSSH is enabled
SSH_PASSWORD=

# Enable Tailscale SSH
ENABLE_TAILSCALED=false

# Tailscale auth key for initial enrollment when Tailscale is enabled
TS_AUTHKEY=

# Hostname used to identify this container in your tailnet
TS_HOSTNAME=devcontainer-ssh

# Optional host directory mount for VS Code Dev Containers extension
WORKSPACE_PATH=
```

- Optionally, set `ENABLE_OPENSSH` to `false` to disable the OpenSSH daemon.
- Set `SSH_PASSWORD` to the password you want to use to log in over OpenSSH.
- Optionally, set `SSH_PORT` to another port if port 2222 is already in use.
- Optionally, set `ENABLE_TAILSCALED` to `true` to enable Tailscale SSH.
- Set `TS_AUTHKEY` to your Tailscale auth key. For details, see the [Tailscale documentation](https://tailscale.com/docs/features/access-control/auth-keys).
- Optionally, set `TS_HOSTNAME` to the name you want to use when connecting over your tailnet.
- Optionally, set `WORKSPACE_PATH` to a host directory to make it available at `/workspaces` when using [VS Code Dev Containers](https://code.visualstudio.com/docs/devcontainers/containers). Leave it unset if you want to keep your workspace files inside the container.

### 3. Configure `docker-compose.yml` file (Optional)

To mount a host directory inside the container, replace the contents of the downloaded `docker-compose.yml` with the configuration below.

```yaml
services:
    devcontainer:
        image: ghcr.io/paper9oll/devcontainer-ssh:latest
        container_name: devcontainer
        restart: unless-stopped
        env_file:
            - .env
        ports:
            - '${SSH_PORT}:22'
        volumes:
            - dev-home:/home/vscode
            - dev-hostkeys:/ssh-host-keys
            - dev-tailscale-state:/var/lib/tailscale
            - ${WORKSPACE_PATH}:/workspaces
        healthcheck:
            disable: false

volumes:
    dev-home:
    dev-hostkeys:
    dev-tailscale-state:
```

### 4. Start the container

From the directory you created in step 1, run:

```sh
docker compose up -d
```

## Post-installation

### OpenSSH

When OpenSSH is enabled, connect using the Docker host's IP address and the mapped port:

```sh
ssh -p 2222 vscode@IP-ADDRESS
```

Enter the password set in `SSH_PASSWORD` when prompted.

You're all set!

> [!NOTE]
> If you changed `SSH_PORT`, use that port instead.<br />Replace `IP-ADDRESS` with the IP address of your Docker host.

### Tailscale SSH

When Tailscale is enabled, connect from a device on your tailnet using the configured hostname:

```sh
ssh vscode@devcontainer-ssh
```

You're all set!

> [!NOTE]
> If you changed `TS_HOSTNAME`, use that name instead.

## License

This project is licensed under [MIT](LICENSE) and is provided without warranty.

### Third-Party Notices

This project includes third-party components that are subject to their own copyright and license terms. These terms are documented in [Third-Party Notices](THIRD_PARTY_NOTICES.md).
