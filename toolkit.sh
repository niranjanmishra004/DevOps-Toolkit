#!/bin/bash
# ============================================================================
#  DevOps Engineer Toolkit Installer
#  Installs: Docker, Kind, kubectl, Helm, Terraform, k9s, kubectx/kubens,
#            AWS CLI v2, jq, yq, git, tmux, htop
#  Features: colored output, spinner animations, progress tracking,
#            idempotent (safe to re-run), version summary at the end
# ============================================================================

set -e
set -o pipefail

# ----------------------------------------------------------------------------
# Colors & symbols
# ----------------------------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m' # No Color

CHECK="✅"
CROSS="❌"
PACKAGE="📦"
ROCKET="🚀"
GEAR="⚙️"
PARTY="🎉"

TOTAL_STEPS=11
CURRENT_STEP=0

# ----------------------------------------------------------------------------
# Spinner animation — runs a command in the background and shows a spinner
# Usage: run_with_spinner "Message to show" "command to run"
# ----------------------------------------------------------------------------
run_with_spinner() {
  local msg="$1"
  local cmd="$2"
  local logfile
  logfile=$(mktemp)

  eval "$cmd" >"$logfile" 2>&1 &
  local pid=$!

  local spin='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
  local i=0
  tput civis 2>/dev/null || true  # hide cursor

  while kill -0 "$pid" 2>/dev/null; do
    i=$(( (i+1) % ${#spin} ))
    printf "\r${CYAN}${spin:$i:1}${NC} ${msg}"
    sleep 0.1
  done

  wait "$pid"
  local exit_code=$?
  tput cnorm 2>/dev/null || true  # show cursor

  if [ $exit_code -eq 0 ]; then
    printf "\r${GREEN}${CHECK}${NC} ${msg}   \n"
  else
    printf "\r${RED}${CROSS}${NC} ${msg} — failed. See log: $logfile\n"
    echo -e "${RED}--- last 20 lines of output ---${NC}"
    tail -n 20 "$logfile"
    exit $exit_code
  fi
  rm -f "$logfile"
}

# ----------------------------------------------------------------------------
# Progress bar header for each step
# ----------------------------------------------------------------------------
step_header() {
  CURRENT_STEP=$((CURRENT_STEP + 1))
  local title="$1"
  local pct=$(( CURRENT_STEP * 100 / TOTAL_STEPS ))
  local filled=$(( pct / 5 ))
  local empty=$(( 20 - filled ))
  local bar
  bar=$(printf "%${filled}s" | tr ' ' '█')
  bar+=$(printf "%${empty}s" | tr ' ' '░')
  echo
  echo -e "${MAGENTA}[${bar}] ${pct}%${NC}  ${BOLD}Step ${CURRENT_STEP}/${TOTAL_STEPS}: ${title}${NC}"
}

banner() {
  echo -e "${BLUE}${BOLD}"
  cat <<'EOF'
   ____              ___              _____           _ _    _ _
  |  _ \  _____   __/ _ \ _ __  ___  |_   _|__   ___ | | | _(_) |_
  | | | |/ _ \ \ / / | | | '_ \/ __|   | |/ _ \ / _ \| | |/ / | __|
  | |_| |  __/\ V /| |_| | |_) \__ \   | | (_) | (_) | |   <| | |_
  |____/ \___| \_/  \___/| .__/|___/   |_|\___/ \___/|_|_|\_\_|\__|
                          |_|
EOF
  echo -e "${NC}"
  echo -e "${CYAN}${ROCKET} DevOps Environment Bootstrap — Docker, Kubernetes & IaC tooling${NC}"
  echo -e "${CYAN}------------------------------------------------------------------${NC}"
}

detect_arch() {
  ARCH=$(uname -m)
  case "$ARCH" in
    x86_64) ARCH_ALIAS="amd64" ;;
    aarch64|arm64) ARCH_ALIAS="arm64" ;;
    *) echo -e "${RED}${CROSS} Unsupported architecture: $ARCH${NC}"; exit 1 ;;
  esac
}

# ============================================================================
# MAIN
# ============================================================================
banner
detect_arch
echo -e "${GEAR} Detected architecture: ${BOLD}${ARCH} (${ARCH_ALIAS})${NC}"

# ----------------------------------------------------------------------------
# 1. System update
# ----------------------------------------------------------------------------
step_header "Updating package index"
run_with_spinner "Refreshing apt package lists" "sudo apt-get update -y"

# ----------------------------------------------------------------------------
# 2. Base utilities
# ----------------------------------------------------------------------------
step_header "Installing base utilities (curl, git, jq, tmux, htop, unzip)"
if ! dpkg -s curl git jq tmux htop unzip ca-certificates gnupg lsb-release &>/dev/null; then
  run_with_spinner "Installing base packages" \
    "sudo apt-get install -y curl git jq tmux htop unzip ca-certificates gnupg lsb-release"
else
  echo -e "${GREEN}${CHECK}${NC} Base utilities already installed."
fi

# ----------------------------------------------------------------------------
# 3. Docker
# ----------------------------------------------------------------------------
step_header "Installing Docker"
if ! command -v docker &>/dev/null; then
  run_with_spinner "Installing Docker Engine" "sudo apt-get install -y docker.io"
  run_with_spinner "Adding $USER to docker group" "sudo usermod -aG docker \"$USER\""
  echo -e "${YELLOW}⚠  Log out/in (or run 'newgrp docker') for group changes to apply.${NC}"
else
  echo -e "${GREEN}${CHECK}${NC} Docker already installed."
fi

# ----------------------------------------------------------------------------
# 4. Kind
# ----------------------------------------------------------------------------
step_header "Installing Kind (Kubernetes in Docker)"
if ! command -v kind &>/dev/null; then
  KIND_VERSION="v0.29.0"
  run_with_spinner "Downloading Kind ${KIND_VERSION}" \
    "curl -Lo ./kind https://kind.sigs.k8s.io/dl/${KIND_VERSION}/kind-linux-${ARCH_ALIAS} && chmod +x ./kind && sudo mv ./kind /usr/local/bin/kind"
else
  echo -e "${GREEN}${CHECK}${NC} Kind already installed."
fi

# ----------------------------------------------------------------------------
# 5. kubectl
# ----------------------------------------------------------------------------
step_header "Installing kubectl"
if ! command -v kubectl &>/dev/null; then
  run_with_spinner "Resolving latest stable kubectl version" \
    "curl -Ls https://dl.k8s.io/release/stable.txt -o /tmp/kubectl_version.txt"
  KVERSION=$(cat /tmp/kubectl_version.txt)
  run_with_spinner "Downloading kubectl ${KVERSION}" \
    "curl -Lo ./kubectl https://dl.k8s.io/release/${KVERSION}/bin/linux/${ARCH_ALIAS}/kubectl && chmod +x ./kubectl && sudo mv ./kubectl /usr/local/bin/kubectl"
else
  echo -e "${GREEN}${CHECK}${NC} kubectl already installed."
fi

# ----------------------------------------------------------------------------
# 6. Helm
# ----------------------------------------------------------------------------
step_header "Installing Helm"
if ! command -v helm &>/dev/null; then
  run_with_spinner "Installing Helm via official script" \
    "curl -fsSL -o /tmp/get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 && chmod +700 /tmp/get_helm.sh && /tmp/get_helm.sh"
else
  echo -e "${GREEN}${CHECK}${NC} Helm already installed."
fi

# ----------------------------------------------------------------------------
# 7. Terraform
# ----------------------------------------------------------------------------
step_header "Installing Terraform"
if ! command -v terraform &>/dev/null; then
  run_with_spinner "Adding HashiCorp GPG key & repo" \
    "wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg && \
     echo \"deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com \$(lsb_release -cs) main\" | sudo tee /etc/apt/sources.list.d/hashicorp.list"
  run_with_spinner "Installing Terraform package" \
    "sudo apt-get update -y && sudo apt-get install -y terraform"
else
  echo -e "${GREEN}${CHECK}${NC} Terraform already installed."
fi

# ----------------------------------------------------------------------------
# 8. AWS CLI v2
# ----------------------------------------------------------------------------
step_header "Installing AWS CLI v2"
if ! command -v aws &>/dev/null; then
  AWS_ARCH="x86_64"
  [ "$ARCH_ALIAS" = "arm64" ] && AWS_ARCH="aarch64"
  run_with_spinner "Downloading & installing AWS CLI v2" \
    "curl -s \"https://awscli.amazonaws.com/awscli-exe-linux-${AWS_ARCH}.zip\" -o /tmp/awscliv2.zip && \
     unzip -q -o /tmp/awscliv2.zip -d /tmp && sudo /tmp/aws/install --update"
else
  echo -e "${GREEN}${CHECK}${NC} AWS CLI already installed."
fi

# ----------------------------------------------------------------------------
# 9. k9s (terminal UI for Kubernetes)
# ----------------------------------------------------------------------------
step_header "Installing k9s"
if ! command -v k9s &>/dev/null; then
  run_with_spinner "Downloading & installing k9s" \
    "curl -Ls \"https://github.com/derailed/k9s/releases/latest/download/k9s_Linux_${ARCH_ALIAS}.tar.gz\" -o /tmp/k9s.tar.gz && \
     tar -xzf /tmp/k9s.tar.gz -C /tmp k9s && sudo mv /tmp/k9s /usr/local/bin/k9s && sudo chmod +x /usr/local/bin/k9s"
else
  echo -e "${GREEN}${CHECK}${NC} k9s already installed."
fi

# ----------------------------------------------------------------------------
# 10. kubectx & kubens
# ----------------------------------------------------------------------------
step_header "Installing kubectx & kubens"
if ! command -v kubectx &>/dev/null; then
  run_with_spinner "Installing kubectx & kubens" \
    "sudo git clone --depth 1 https://github.com/ahmetb/kubectx /opt/kubectx 2>/dev/null || true; \
     sudo ln -sf /opt/kubectx/kubectx /usr/local/bin/kubectx; \
     sudo ln -sf /opt/kubectx/kubens /usr/local/bin/kubens"
else
  echo -e "${GREEN}${CHECK}${NC} kubectx/kubens already installed."
fi

# ----------------------------------------------------------------------------
# 11. yq (YAML processor)
# ----------------------------------------------------------------------------
step_header "Installing yq"
if ! command -v yq &>/dev/null; then
  run_with_spinner "Downloading yq" \
    "sudo curl -Lo /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_${ARCH_ALIAS} && sudo chmod +x /usr/local/bin/yq"
else
  echo -e "${GREEN}${CHECK}${NC} yq already installed."
fi

# ============================================================================
# SUMMARY
# ============================================================================
echo
echo -e "${CYAN}------------------------------------------------------------------${NC}"
echo -e "${BOLD}${PARTY} Installed Toolchain Summary${NC}"
echo -e "${CYAN}------------------------------------------------------------------${NC}"

print_version() {
  local name="$1"
  local cmd="$2"
  printf "%-12s" "$name"
  if command -v "$name" &>/dev/null; then
    echo -e "${GREEN}${CHECK}${NC} $(eval "$cmd" 2>/dev/null | head -n1)"
  else
    echo -e "${RED}${CROSS} not found${NC}"
  fi
}

print_version "docker"    "docker --version"
print_version "kind"      "kind --version"
print_version "kubectl"   "kubectl version --client 2>/dev/null | head -n1"
print_version "helm"      "helm version --short"
print_version "terraform" "terraform --version"
print_version "aws"       "aws --version"
print_version "k9s"       "k9s version --short"
print_version "kubectx"   "echo installed"
print_version "kubens"    "echo installed"
print_version "yq"        "yq --version"
print_version "jq"        "jq --version"

echo -e "${CYAN}------------------------------------------------------------------${NC}"
echo -e "${GREEN}${BOLD}${PARTY} All done! Your DevOps toolkit is ready to roll.${NC}"
echo -e "${YELLOW}👉 If Docker was just installed, log out/in or run 'newgrp docker' to use it without sudo.${NC}"
echo
