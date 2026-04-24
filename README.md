# NIPA GPU Notebook Setup

A one-shot setup script for KakaoCloud NIPA GPU notebook instances.  
Run it once in the notebook's web terminal right after launching a new notebook.

## What it does

| Step | Action |
|------|--------|
| 1 | Changes the user's home directory to `/home/{user-name}` (separates it from the shared `/home/jovyan`) |
| 2 | Grants passwordless `sudo` to the user via `/etc/sudoers.d/` |
| 3 | Adds the provided SSH public key(s) to `~/.ssh/authorized_keys` |
| 4 | Sets correct ownership (`{user-name}:users`) and permissions (`755`/`700`/`600`) on the home directory and `.ssh`. By default only the paths this script creates are chowned; pass `--chown-homedir` to recursively fix the entire home directory. |
| 5 | Disables SSH password authentication in `/etc/ssh/sshd_config` and restarts the SSH service |

## Prerequisites

- You must be running inside the notebook's **web terminal** (as the `jovyan` user, which already has `sudo` access by default).
- The workspace volume must have been mounted at `/home/{user-name}` (not the default `/home/jovyan`) when creating the notebook — see the section below.

## Usage

```bash
bash setup.bash \
    --user-name <name> \
    --ssh-public-key "<key1>" ["<key2>" ...] \
    [--chown-homedir]
```

### Arguments

| Argument | Required | Description |
|----------|----------|-------------|
| `--user-name` | Yes | Your Linux username on the notebook (e.g. `km.kim`) |
| `--ssh-public-key` | No | One or more SSH public keys to authorize. Quote each key. If omitted, no keys are added to `authorized_keys`. |
| `--chown-homedir` | No | Recursively fix ownership of the entire home directory in step 4. Off by default because scanning large home directories (conda envs, datasets) is slow; the script always chowns the paths it creates itself. Use this the first time you set up a notebook, or when ownership is suspect. |

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

First-time setup (recursively fix ownership of the whole home directory):

```bash
bash setup.bash \
    --user-name km.kim \
    --ssh-public-key "ssh-ed25519 AAAA...yourkey user@machine" \
    --chown-homedir
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
