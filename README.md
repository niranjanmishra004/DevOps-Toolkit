# DevOps-Toolkit

A one-shot DevOps environment bootstrapper built in Bash that installs and configures the entire toolchain a DevOps/Cloud engineer needs—Docker, Kubernetes tooling, Infrastructure as Code (IaC), GitOps, and cloud CLIs—in a single command.

Provides universal support for all major Linux distributions: Debian, Ubuntu, Fedora, RHEL, CentOS, Rocky, AlmaLinux, Arch, Manjaro, openSUSE, SLES, and Alpine.

The script is idempotent and safe to re-run multiple times. Already-installed tools are automatically skipped.

---

## Features

- Docker Engine installation with user group setup
- Kubernetes tooling:
  - Kind (Kubernetes in Docker)
  - kubectl (latest stable)
  - Helm
  - k9s (terminal UI for Kubernetes)
  - kubectx & kubens
- GitOps—ArgoCD CLI
- Infrastructure as Code—Terraform (via official repos)
- AWS CLI v2
- Everyday utilities—git, jq, yq, tmux, htop, unzip, wget
- Idempotent design—safe to re-run, automatically skips already-installed tools
- Multi-distro support—auto-detects Linux distro and uses correct package manager
- Colorized terminal output
- Spinner and progress bar animations for every installation step
- Version summary table printed at the end
- Error handling with detailed logs on failure

---

## Sample Output

```
   ____              ___              _____           _ _    _ _
  |  _ \  _____   __/ _ \ _ __  ___  |_   _|__   ___ | | | _(_) |_
  | | | |/ _ \ \ / / | | | '_ \/ __|   | |/ _ \ / _ \| | |/ / | __|
  | |_| |  __/\ V /| |_| | |_) \__ \   | | (_) | (_) | |   <| | |_
  |____/ \___| \_/  \___/| .__/|___/   |_|\___/ \___/|_|_|\_\_|\__|
                          |_|

DevOps Environment Bootstrap — Docker, Kubernetes & IaC tooling
------------------------------------------------------------------
Detected Linux: Ubuntu 22.04 (ubuntu)
Package Manager: apt
Architecture: x86_64 (amd64)

[##░░░░░░░░░░░░░░░░] 8%  Step 1/12: Updating package manager
✓ Refreshing apt package lists

[####░░░░░░░░░░░░░░] 17%  Step 2/12: Installing base utilities
✓ Installing base packages (apt)

[######░░░░░░░░░░░░] 25%  Step 3/12: Installing Docker
✓ Installing Docker Engine (Debian)
✓ Adding user to docker group
Note: Log out/in (or run 'newgrp docker') for group changes to apply.

[########░░░░░░░░░░] 33%  Step 4/12: Installing Kind (Kubernetes in Docker)
✓ Downloading Kind v0.29.0

[##########░░░░░░░░] 42%  Step 5/12: Installing kubectl
✓ Resolving latest stable kubectl version
✓ Downloading kubectl v1.31.0

...

------------------------------------------------------------------
Installation Summary
------------------------------------------------------------------
docker       ✓ Docker version 27.0.1
kind         ✓ kind version 0.29.0
kubectl      ✓ Client Version: v1.31.0
helm         ✓ v3.14.0
terraform    ✓ Terraform v1.8.0
aws          ✓ aws-cli/2.15.0
k9s          ✓ k9s version 0.32.4
kubectx      ✓ installed
kubens       ✓ installed
yq           ✓ yq (https://github.com/mikefarah/yq/) version 4.40.5
jq           ✓ jq-1.7
argocd       ✓ argocd: v2.10.3

------------------------------------------------------------------
Installation complete. Your DevOps toolkit is ready to use.
Note: If Docker was just installed, log out/in or run 'newgrp docker' to use it without sudo.
```

---

## Installed Tools

| Tool | Purpose | Notes |
|------|---------|-------|
| Docker | Container runtime | Available on all distros |
| Kind | Local Kubernetes clusters in Docker | Binary download |
| kubectl | Kubernetes CLI | Latest stable from k8s.io |
| Helm | Kubernetes package manager | Official install script |
| Terraform | Infrastructure as Code | Distro-specific repos |
| AWS CLI v2 | AWS cloud management | Official installer |
| k9s | Terminal UI for Kubernetes clusters | Binary download |
| kubectx / kubens | Fast context and namespace switching | GitHub clone |
| ArgoCD CLI | GitOps continuous deployment | GitHub releases |
| jq / yq | JSON and YAML processing | Package manager and binary |
| git, tmux, htop, wget | Everyday CLI essentials | Package manager |

---

## Installation and Usage

### Step 1: Clone the repository

```bash
git clone https://github.com/niranjanmishra004/DevOps-Toolkit.git
cd DevOps-Toolkit
```

### Step 2: Make the script executable

```bash
chmod +x toolkit.sh
```

### Step 3: Run the script

```bash
./toolkit.sh
```

### Important Notes

- The script requires sudo privileges for system-level installations
- If Docker was just installed, log out and back in (or run `newgrp docker`) to use it without sudo
- The script is safe to re-run at any time; already-installed tools are automatically skipped

---

## Supported Linux Distributions

| Family | Distributions | Package Manager |
|--------|--------------|-----------------|
| Debian-based | Ubuntu, Debian | apt |
| RHEL-based | Fedora, RHEL, CentOS, Rocky, AlmaLinux | dnf |
| Arch-based | Arch, Manjaro | pacman |
| openSUSE-based | openSUSE, SLES | zypper |
| Alpine-based | Alpine | apk |

The script automatically detects your distribution and uses the appropriate package manager and installation methods.

---

## How It Works

1. Distribution Detection—reads /etc/os-release to identify Linux distribution and package manager
2. Architecture Detection—detects CPU architecture (x86_64 or arm64) via uname -m
3. Smart Installation—checks each tool before installing; skips if already present
4. Official Sources—all tools installed from official repos and sources:
   - Package managers (apt, dnf, pacman, zypper, apk)
   - Official GitHub releases (kubectl, helm, k9s, argocd, etc.)
   - Official install scripts (Helm, AWS CLI)
   - Distro-specific repositories (Terraform, Docker)
5. Progress Tracking—displays spinner and progress bar for every installation step
6. Version Summary—prints installed version of each tool at completion

---

## Project Structure

```
DevOps-Toolkit/
├── toolkit.sh
└── README.md
```

---

## Use Cases

- Bootstrapping fresh VMs—spin up a new cloud instance and get a full DevOps environment in minutes
- Local Kubernetes learning—Kind, kubectl, and k9s for local Kubernetes development
- IaC setup—Terraform, AWS CLI, and related tools ready for infrastructure projects
- GitOps workflows—ArgoCD CLI for continuous deployment management
- Team standardization—ensure all team members have identical tooling
- CI/CD runner setup—pre-equip container images or CI agents
- Container image provisioning—Dockerfile base image with all tools pre-installed

---

## Motivation

Setting up a DevOps workstation typically involves:
- Finding and running 15+ separate install commands
- Hunting through multiple documentation pages
- Dealing with distribution-specific differences
- Managing version compatibility issues

DevOps-Toolkit solves this by:
- Single command—one script does it all
- Idempotent design—safe to re-run, no conflicts
- Universal support—works across all major Linux distributions
- Automated detection—automatically detects architecture, OS, and existing installations
- Transparent progress—shows progress and version information
- Fast execution—parallel spinners for quick visual feedback

Deploy from a blank Linux machine to a fully equipped DevOps environment in minutes.

---

## Customization

You can modify the script to add new tools or adjust existing ones.

### Adding a new tool

```bash
step_header "Installing MyTool"
if ! is_installed mytool; then
  run_with_spinner "Downloading MyTool" \
    "curl -Lo /usr/local/bin/mytool https://... && chmod +x /usr/local/bin/mytool"
else
  echo -e "${GREEN}${CHECK}${NC} MyTool already installed."
fi
```

### Changing tool versions

```bash
KIND_VERSION="v0.29.0"  # Update this line
```

### Adjusting package installations per distribution

The script uses case statements to handle distribution-specific packages:

```bash
case "$DISTRO" in
  ubuntu|debian)
    pkg_install package-name
    ;;
  fedora|rhel|centos|rocky|almalinux)
    pkg_install package-name
    ;;
esac
```

---

## Contributing

Contributions are welcome. Areas for enhancement include:
- Additional tools (GCP CLI, Azure CLI, Terraform Cloud, etc.)
- Support for more Linux distributions
- Improved error recovery mechanisms
- Cross-platform support (macOS, Windows WSL2)

To contribute, fork the repository, add your features, and submit a pull request.

## License

This project is distributed under the MIT License.

## Support

For questions, bug reports, or feature requests, please open an issue on GitHub.

## Resources

- Docker Documentation: https://docs.docker.com/
- Kubernetes Official Documentation: https://kubernetes.io/docs/
- Helm: https://artifacthub.io/
- Terraform: https://registry.terraform.io/
- AWS CLI Documentation: https://docs.aws.amazon.com/cli/
- ArgoCD: https://argo-cd.readthedocs.io/
- k9s: https://k9scli.io/

## Troubleshooting

### Script fails with "command not found"

Ensure the script is executable:
```bash
chmod +x toolkit.sh
```

### Docker commands still require sudo after installation

Log out and back in (or restart the terminal), or run:
```bash
newgrp docker
```

### Some tools fail to install

Check the error log printed at the end of each failed step. Verify that you have:
- A working internet connection
- Sufficient disk space
- sudo privileges

### Distribution not detected

If your distribution is not recognized, open an issue and provide the output of:
```bash
cat /etc/os-release
```
