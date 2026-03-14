#!/usr/bin/env bash
set -euo pipefail

# ---------------------------------------------------------------------------
# setup.bash — Post-launch notebook setup for KakaoCloud NIPA GPU notebooks
# ---------------------------------------------------------------------------

usage() {
    cat <<EOF
Usage: $0 --user-name <name> --ssh-public-key "<key1>" ["<key2>" ...]

Required:
  --user-name       The Linux user name for this notebook (e.g. kyungminkim)
  --ssh-public-key  One or more SSH public keys to authorize (space-separated,
                    each key quoted)

Optional:
  -h, --help        Show this help message
EOF
    exit 1
}

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------
USER_NAME=""
SSH_KEYS=()

while [[ $# -gt 0 ]]; do
    case "$1" in
        --user-name)
            [[ -z "${2:-}" ]] && { echo "ERROR: --user-name requires a value"; usage; }
            USER_NAME="$2"
            shift 2
            ;;
        --ssh-public-key)
            shift
            if [[ $# -eq 0 || "$1" == --* ]]; then
                echo "ERROR: --ssh-public-key requires at least one key value"
                usage
            fi
            while [[ $# -gt 0 && "$1" != --* ]]; do
                SSH_KEYS+=("$1")
                shift
            done
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo "ERROR: Unknown argument: $1"
            usage
            ;;
    esac
done

# ---------------------------------------------------------------------------
# Validate required arguments
# ---------------------------------------------------------------------------
if [[ -z "$USER_NAME" ]]; then
    echo "ERROR: --user-name is required"
    usage
fi

if [[ ${#SSH_KEYS[@]} -eq 0 ]]; then
    echo "ERROR: at least one --ssh-public-key is required"
    usage
fi

HOME_DIR="/home/${USER_NAME}"

echo "==> Setup configuration:"
echo "    user-name    : ${USER_NAME}"
echo "    home-dir     : ${HOME_DIR}"
echo "    ssh keys     : ${#SSH_KEYS[@]} key(s)"
echo ""

# ---------------------------------------------------------------------------
# Step 1: Change user's home directory to /home/{user-name}
# ---------------------------------------------------------------------------
echo "==> [1/5] Setting home directory to ${HOME_DIR} ..."
mkdir -p "${HOME_DIR}"
sudo usermod -d "${HOME_DIR}" "${USER_NAME}"
echo "    Done."

# ---------------------------------------------------------------------------
# Step 2: Grant passwordless sudo to the user
# ---------------------------------------------------------------------------
echo "==> [2/5] Granting passwordless sudo to ${USER_NAME} ..."
SUDOERS_FILE="/etc/sudoers.d/${USER_NAME}-nopasswd"
echo "${USER_NAME} ALL=(ALL:ALL) NOPASSWD: ALL" | sudo tee "${SUDOERS_FILE}" > /dev/null
sudo chmod 440 "${SUDOERS_FILE}"
echo "    Done."

# ---------------------------------------------------------------------------
# Step 3: Set up SSH authorized_keys
# ---------------------------------------------------------------------------
echo "==> [3/5] Setting up SSH authorized_keys ..."
SSH_DIR="${HOME_DIR}/.ssh"
AUTH_KEYS="${SSH_DIR}/authorized_keys"

sudo mkdir -p "${SSH_DIR}"

for KEY in "${SSH_KEYS[@]}"; do
    # Avoid duplicate entries
    if sudo grep -qF "$KEY" "${AUTH_KEYS}" 2>/dev/null; then
        echo "    Key already present, skipping: ${KEY:0:40}..."
    else
        echo "$KEY" | sudo tee -a "${AUTH_KEYS}" > /dev/null
        echo "    Added key: ${KEY:0:40}..."
    fi
done
echo "    Done."

# ---------------------------------------------------------------------------
# Step 4: Fix ownership and permissions
# ---------------------------------------------------------------------------
echo "==> [4/5] Fixing ownership and permissions ..."
sudo chown -R "${USER_NAME}:users" "${HOME_DIR}"
sudo chmod 755 "${HOME_DIR}"
sudo chmod 700 "${SSH_DIR}"
sudo chmod 600 "${AUTH_KEYS}"
echo "    Done."

# ---------------------------------------------------------------------------
# Step 5: Disable password authentication in sshd_config
# ---------------------------------------------------------------------------
echo "==> [5/5] Disabling SSH password authentication ..."
SSHD_CONFIG="/etc/ssh/sshd_config"

# Replace or append PasswordAuthentication
if sudo grep -qE "^\s*#?\s*PasswordAuthentication" "${SSHD_CONFIG}"; then
    sudo sed -i 's/^\s*#\?\s*PasswordAuthentication.*/PasswordAuthentication no/' "${SSHD_CONFIG}"
else
    echo "PasswordAuthentication no" | sudo tee -a "${SSHD_CONFIG}" > /dev/null
fi

# Replace or append KbdInteractiveAuthentication
if sudo grep -qE "^\s*#?\s*KbdInteractiveAuthentication" "${SSHD_CONFIG}"; then
    sudo sed -i 's/^\s*#\?\s*KbdInteractiveAuthentication.*/KbdInteractiveAuthentication no/' "${SSHD_CONFIG}"
else
    echo "KbdInteractiveAuthentication no" | sudo tee -a "${SSHD_CONFIG}" > /dev/null
fi

echo "    Restarting SSH service ..."
sudo service ssh stop && sudo service ssh start
echo "    Done."

echo ""
echo "==> Setup complete!"
echo ""
echo "    Next steps (if not already done):"
echo "    1. Add the following to your local ~/.ssh/config:"
echo ""
echo "       Host <your-preferred-host-name>"
echo "           HostName ssh-nipagpu.kakaocloud.com"
echo "           User ${USER_NAME}"
echo "           IdentityFile <path-to-your-private-key>"
echo "           Port <port-shown-at-Use-SSH-column>"
echo ""
echo "    2. Verify SSH key login works before closing this session."
