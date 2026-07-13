#!/bin/bash
# ============================================================================
#  Universal DevOps Engineer Toolkit Installer
#  Supports: Debian, Ubuntu, RHEL, CentOS, Fedora, Arch, openSUSE, Alpine
#  Installs: Docker, Kind, kubectl, Helm, Terraform, k9s, kubectx/kubens,
#            AWS CLI v2, jq, yq, git, tmux, htop, ArgoCD
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

TOTAL_STEPS=12
CURRENT_STEP=0

# ----------------------------------------------------------------------------
# Distribution detection
# ----------------------------------------------------------------------------
detect_distro() {
  if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO="$ID"
    DISTRO_VERSION="$VERSION_ID"
    DISTRO_NAME="$NAME"
  elif [ -f /etc/lsb-release ]; then
    . /etc/lsb-release
    DISTRO=$(echo "$DISTRIB_ID" | tr '[:upper:]' '[:lower:]')
    DISTRO_VERSION="$DISTRIB_RELEASE"
    DISTRO_NAME="$DISTRIB_DESCRIPTION"
  else
    echo -e "${RED}${CROSS} Unable to detect Linux distribution${NC}"
    exit 1
  fi

  # Normalize distro names
  case "$DISTRO" in
    ubuntu|debian) PKG_MGR="apt" ;;
    fedora) PKG_MGR="dnf" ;;
    rhel|centos|rocky|almalinux) PKG_MGR="dnf" ;;
    arch|manjaro) PKG_MGR="pacman" ;;
    opensuse*|sles) PKG_MGR="zypper" ;;
    alpine) PKG_MGR="apk" ;;
    *) 
      echo -e "${RED}${CROSS} Unsupported distribution: $DISTRO${NC}"
      echo -e "${YELLOW}Supported: Debian, Ubuntu, Fedora, RHEL, CentOS, Arch, openSUSE, Alpine${NC}"
      exit 1 
      ;;
  esac
}

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

# Package manager abstraction layer
# Usage: pkg_install "package1" "package2"
# ----------------------------------------------------------------------------
pkg_install() {
  case "$PKG_MGR" in
    apt)
      sudo apt-get update -y >/dev/null 2>&1 || true
      sudo apt-get install -y "$@"
      ;;
    dnf)
      sudo dnf install -y "$@"
      ;;
    pacman)
      sudo pacman -Sy --noconfirm "$@"
      ;;
    zypper)
      sudo zypper install -y "$@"
      ;;
    apk)
      sudo apk add "$@"
      ;;
    *)
      echo -e "${RED}${CROSS} Unknown package manager: $PKG_MGR${NC}"
      exit 1
      ;;
  esac
}

# Check if package/command is installed
# Usage: is_installed "command_name"
# ----------------------------------------------------------------------------
is_installed() {
  command -v "$1" &>/dev/null
}

# ============================================================================
# MAIN
# ============================================================================
banner
detect_distro
detect_arch

echo -e "${GEAR} Detected Linux: ${BOLD}${DISTRO_NAME} (${DISTRO})${NC}"
echo -e "${GEAR} Package Manager: ${BOLD}${PKG_MGR}${NC}"
echo -e "${GEAR} Architecture: ${BOLD}${ARCH} (${ARCH_ALIAS})${NC}"

# Check for sudo/root
if [ "$EUID" -ne 0 ] && ! sudo -n true 2>/dev/null; then
  echo -e "${YELLOW}⚠  This script requires sudo. Testing sudo access...${NC}"
  sudo -v
fi

# ----------------------------------------------------------------------------
# 1. System update
# ----------------------------------------------------------------------------
step_header "Updating package manager"
case "$PKG_MGR" in
  apt) run_with_spinner "Refreshing apt package lists" "sudo apt-get update -y" ;;
  dnf) run_with_spinner "Refreshing dnf package lists" "sudo dnf check-update -y || true" ;;
  pacman) run_with_spinner "Refreshing pacman package lists" "sudo pacman -Sy" ;;
  zypper) run_with_spinner "Refreshing zypper package lists" "sudo zypper refresh" ;;
  apk) run_with_spinner "Refreshing apk package lists" "sudo apk update" ;;
esac

# ----------------------------------------------------------------------------
# 2. Base utilities
# ----------------------------------------------------------------------------
step_header "Installing base utilities"
if ! is_installed curl || ! is_installed git || ! is_installed jq; then
  case "$PKG_MGR" in
    apt)
      run_with_spinner "Installing base packages (apt)" \
        "sudo apt-get install -y curl git jq tmux htop unzip ca-certificates gnupg lsb-release"
      ;;
    dnf)
      run_with_spinner "Installing base packages (dnf)" \
        "sudo dnf install -y curl git jq tmux htop unzip ca-certificates gnupg"
      ;;
    pacman)
      run_with_spinner "Installing base packages (pacman)" \
        "sudo pacman -Sy --noconfirm curl git jq tmux htop unzip ca-certificates gnupg"
      ;;
    zypper)
      run_with_spinner "Installing base packages (zypper)" \
        "sudo zypper install -y curl git jq tmux htop unzip ca-certificates gnupg"
      ;;
    apk)
      run_with_spinner "Installing base packages (apk)" \
        "sudo apk add curl git jq tmux htop unzip ca-certificates gnupg"
      ;;
  esac
else
  echo -e "${GREEN}${CHECK}${NC} Base utilities already installed."
fi

# Install wget if not present (needed for some tools)
if ! is_installed wget; then
  case "$PKG_MGR" in
    apt) run_with_spinner "Installing wget" "sudo apt-get install -y wget" ;;
    dnf) run_with_spinner "Installing wget" "sudo dnf install -y wget" ;;
    pacman) run_with_spinner "Installing wget" "sudo pacman -Sy --noconfirm wget" ;;
    zypper) run_with_spinner "Installing wget" "sudo zypper install -y wget" ;;
    apk) run_with_spinner "Installing wget" "sudo apk add wget" ;;
  esac
fi

# Install sudo if not present (unlikely but just in case)
if ! is_installed sudo; then
  case "$PKG_MGR" in
    apt) pkg_install sudo ;;
    dnf) pkg_install sudo ;;
    pacman) pkg_install sudo ;;
    zypper) pkg_install sudo ;;
    apk) pkg_install sudo ;;
  esac
fi

# ----------------------------------------------------------------------------
# 3. Docker
# ----------------------------------------------------------------------------
step_header "Installing Docker"
if ! is_installed docker; then
  case "$DISTRO" in
    ubuntu|debian)
      run_with_spinner "Installing Docker Engine (Debian)" \
        "sudo apt-get install -y docker.io"
      ;;
    fedora|rhel|centos|rocky|almalinux)
      run_with_spinner "Installing Docker Engine (RHEL-based)" \
        "sudo dnf install -y docker"
      ;;
    arch|manjaro)
      run_with_spinner "Installing Docker Engine (Arch)" \
        "sudo pacman -Sy --noconfirm docker"
      ;;
    opensuse*|sles)
      run_with_spinner "Installing Docker Engine (openSUSE)" \
        "sudo zypper install -y docker"
      ;;
    alpine)
      run_with_spinner "Installing Docker Engine (Alpine)" \
        "sudo apk add docker"
      ;;
  esac
  
  run_with_spinner "Adding $USER to docker group" "sudo usermod -aG docker \"$USER\""
  echo -e "${YELLOW}⚠  Log out/in (or run 'newgrp docker') for group changes to apply.${NC}"
else
  echo -e "${GREEN}${CHECK}${NC} Docker already installed."
fi

# ----------------------------------------------------------------------------
# 4. Kind
# ----------------------------------------------------------------------------
step_header "Installing Kind (Kubernetes in Docker)"
if ! is_installed kind; then
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
if ! is_installed kubectl; then
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
if ! is_installed helm; then
  run_with_spinner "Installing Helm via official script" \
    "curl -fsSL -o /tmp/get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 && chmod +700 /tmp/get_helm.sh && /tmp/get_helm.sh"
else
  echo -e "${GREEN}${CHECK}${NC} Helm already installed."
fi

# ----------------------------------------------------------------------------
# 7. Terraform
# ----------------------------------------------------------------------------
step_header "Installing Terraform"
if ! is_installed terraform; then
  case "$DISTRO" in
    ubuntu|debian)
      run_with_spinner "Adding HashiCorp GPG key & repo (Debian)" \
        "wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg && \
         echo \"deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com \$(lsb_release -cs) main\" | sudo tee /etc/apt/sources.list.d/hashicorp.list"
      run_with_spinner "Installing Terraform package" \
        "sudo apt-get update -y && sudo apt-get install -y terraform"
      ;;
    fedora|rhel|centos|rocky|almalinux)
      run_with_spinner "Adding HashiCorp repo & installing Terraform (RHEL)" \
        "sudo dnf install -y dnf-plugins-core && \
         sudo dnf config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo && \
         sudo dnf install -y terraform"
      ;;
    arch|manjaro)
      run_with_spinner "Installing Terraform (Arch)" \
        "sudo pacman -Sy --noconfirm terraform"
      ;;
    opensuse*|sles)
      run_with_spinner "Installing Terraform (openSUSE)" \
        "sudo zypper install -y terraform"
      ;;
    alpine)
      run_with_spinner "Installing Terraform (Alpine)" \
        "sudo apk add terraform"
      ;;
  esac
else
  echo -e "${GREEN}${CHECK}${NC} Terraform already installed."
fi

# ----------------------------------------------------------------------------
# 8. AWS CLI v2
# ----------------------------------------------------------------------------
step_header "Installing AWS CLI v2"
if ! is_installed aws; then
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
if ! is_installed k9s; then
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
if ! is_installed kubectx; then
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
if ! is_installed yq; then
  run_with_spinner "Downloading yq" \
    "sudo curl -Lo /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_${ARCH_ALIAS} && sudo chmod +x /usr/local/bin/yq"
else
  echo -e "${GREEN}${CHECK}${NC} yq already installed."
fi

# ----------------------------------------------------------------------------
# 12. ArgoCD CLI
# ----------------------------------------------------------------------------
step_header "Installing ArgoCD CLI"
if ! is_installed argocd; then
  run_with_spinner "Downloading ArgoCD CLI" \
    "curl -sSL -o /tmp/argocd-linux-${ARCH_ALIAS} https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-${ARCH_ALIAS} && \
     chmod +x /tmp/argocd-linux-${ARCH_ALIAS} && sudo mv /tmp/argocd-linux-${ARCH_ALIAS} /usr/local/bin/argocd"
else
  echo -e "${GREEN}${CHECK}${NC} ArgoCD CLI already installed."
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
  if is_installed "$name"; then
    echo -e "${GREEN}${CHECK}${NC} $(eval "$cmd" 2>/dev/null | head -n1)"
  else
    echo -e "${RED}${CROSS}${NC} not found${NC}"
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
print_version "argocd"    "argocd version --client 2>/dev/null | head -n1"

echo -e "${CYAN}------------------------------------------------------------------${NC}"
echo -e "${GREEN}${BOLD}${PARTY} All done! Your DevOps toolkit is ready to roll.${NC}"
echo -e "${YELLOW}👉 If Docker was just installed, log out/in or run 'newgrp docker' to use it without sudo.${NC}"
echo
