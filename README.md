# NIPA GPU Notebook Setup

A one-shot setup script for KakaoCloud NIPA GPU notebook instances.  
Run it once in the notebook's web terminal right after launching a new notebook.

## What it does

| Step | Action |
|------|--------|
| 1 | Changes the user's home directory to `/home/{user-name}` (separates it from the shared `/home/jovyan`) |
| 2 | Grants passwordless `sudo` to the user via `/etc/sudoers.d/` |
| 3 | Adds the provided SSH public key(s) to `~/.ssh/authorized_keys` |
| 4 | Sets correct ownership (`{user-name}:users`) and permissions (`755`/`700`/`600`) on the home directory and `.ssh` |
| 5 | Disables SSH password authentication in `/etc/ssh/sshd_config` and restarts the SSH service |
| 6 | Installs [uv](https://github.com/astral-sh/uv) (if not already installed) and optionally configures a custom cache directory |

## Prerequisites

- You must be running inside the notebook's **web terminal** (as the `jovyan` user, which already has `sudo` access by default).
- The workspace volume must have been mounted at `/home/{user-name}` (not the default `/home/jovyan`) when creating the notebook — see the section below.

## Usage

```bash
bash setup.bash \
    --user-name <name> \
    --ssh-public-key "<key1>" ["<key2>" ...] \
    [--uv-cache-dir <dir>]
```

### Arguments

| Argument | Required | Description |
|----------|----------|-------------|
| `--user-name` | Yes | Your Linux username on the notebook (e.g. `kyungminkim`) |
| `--ssh-public-key` | Yes | One or more SSH public keys to authorize. Quote each key. |
| `--uv-cache-dir` | No | Custom cache directory for uv (e.g. `/asmp-shared/uv-cache`). Omit to use uv's built-in default. |

### Example

```bash
bash setup.bash \
    --user-name kyungminkim \
    --ssh-public-key "ssh-ed25519 AAAA...yourkey user@machine" \
    --uv-cache-dir /asmp-shared/uv-cache
```

Multiple SSH keys:

```bash
bash setup.bash \
    --user-name kyungminkim \
    --ssh-public-key "ssh-ed25519 AAAA...key1 laptop" "ssh-ed25519 AAAA...key2 desktop"
```

## Notebook creation checklist (before running this script)

### CPU / RAM
- GPU 개당 CPU는 최대 239.375~239.5 미만, RAM도 동일 범위 내에서 허용.
- 전체 서버 제한: CPU 896, RAM 16 TiB.
- 실제 할당값 = 입력값 + DIND max CPU/RAM + 1.

### Workspace Volume — recommended setup
1. When prompted for the workspace volume mount path, change it from the default `/home/jovyan` to **`/home/{user-name}`**.  
   This separates your home directory from `jovyan` and avoids permission issues later.
2. If attaching an existing volume, click the trash icon on the pre-filled "new volume" row first, then click **+ Attach existing volume**.

### Data Volumes
- Attach `asmp-shared` (20 TB) and mount it at **`/asmp-shared`** (not under your home directory) to avoid including it in `chown` operations.

### SSH
- Enable the **SSH** toggle in the notebook creation form.

### Advanced Options (DIND)
- Only enable DIND if you specifically need Docker-in-Docker; enabling it reduces the effective CPU/RAM available to your notebook.

## After running this script

### Verify SSH access
From your local machine, add a host entry to `~/.ssh/config`:

```
Host <preferred-name>
    HostName ssh-nipagpu.kakaocloud.com
    User <user-name>
    IdentityFile <path-to-private-key>
    Port <port shown in the "Use SSH" column>
```

Then connect:

```bash
ssh <preferred-name>
```

> **Important:** Verify that key-based SSH login works **before** closing the web terminal session. The script disables password authentication.

### uv cache on shared storage
If your notebook is ephemeral and you want to preserve the uv package cache across notebook restarts, point `--uv-cache-dir` at a path on `asmp-shared`:

```bash
--uv-cache-dir /asmp-shared/uv-cache
```

## References

- [KakaoCloud SSH guide](https://docs.kakaocloud.com/ha-gpu/guide/ssh-guide)
- [uv documentation](https://docs.astral.sh/uv/)
