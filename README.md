# devcontainer-ssh

An SSH-enabled development container based on Microsoft's Dev Container image.

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

### 2. Populate the `.env` file

```env
# Image variant: latest for OpenSSH only, latest-ts for Tailscale SSH
IMAGE_TAG=latest

# Password for LAN access via OpenSSH
SSH_PASSWORD=

# Tailscale auth key for the latest-ts image
# Create one in the Tailscale admin console
TS_AUTHKEY=

# Hostname used to identify this container in your tailnet
TS_HOSTNAME=devcontainer-ssh
```

- Optionally, set `IMAGE_TAG` to `latest-ts` to enable Tailscale SSH.
- Set `SSH_PASSWORD` to the password you want to use to log in over SSH.
- Set `TS_AUTHKEY` to your Tailscale auth key. For details, see the [Tailscale documentation](https://tailscale.com/docs/features/access-control/auth-keys).
- Optionally, set `TS_HOSTNAME` to the name you want to use when connecting over your tailnet.

### 3. Start container

From the directory you created in step 1, run the following command to start the container in the background:

```sh
docker compose up -d
```

## Post-installation

### SSH via LAN

Connect using the Docker host's IP address and the LAN port mapping:

```sh
ssh -p 2222 vscode@IP-ADDRESS
```

Enter the password set in `SSH_PASSWORD` when prompted.

You're all set!

> [!NOTE]
> Replace `IP-ADDRESS` with the IP address of your Docker host.

### Tailscale SSH

For the `latest-ts` variant, connect from a device connected to your tailnet using the configured `TS_HOSTNAME`:

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