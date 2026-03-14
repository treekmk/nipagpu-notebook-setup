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

## Prerequisites

- You must be running inside the notebook's **web terminal** (as the `jovyan` user, which already has `sudo` access by default).
- The workspace volume must have been mounted at `/home/{user-name}` (not the default `/home/jovyan`) when creating the notebook — see the section below.

## Usage

```bash
bash setup.bash \
    --user-name <name> \
    --ssh-public-key "<key1>" ["<key2>" ...]
```

### Arguments

| Argument | Required | Description |
|----------|----------|-------------|
| `--user-name` | Yes | Your Linux username on the notebook (e.g. `km.kim`) |
| `--ssh-public-key` | Yes | One or more SSH public keys to authorize. Quote each key. |

### Example

```bash
bash setup.bash \
    --user-name km.kim \
    --ssh-public-key "ssh-ed25519 AAAA...yourkey user@machine"
```

Multiple SSH keys:

```bash
bash setup.bash \
    --user-name km.kim \
    --ssh-public-key "ssh-ed25519 AAAA...key1 laptop" "ssh-ed25519 AAAA...key2 desktop"
```

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
