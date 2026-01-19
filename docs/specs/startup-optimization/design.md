# Design - Startup Script Optimization

## Overview
The script will follow a modular architecture with robust error handling and logging. It is designed to be executed as a "startup script" on a fresh Debian Bookworm VM.

## Architecture
- **Config Loader**: Parses CLI flags and Environment variables.
- **System Provisioner**: Handles package updates and firewall.
- **Nginx Manager**: Installs Nginx and compiles Brotli.
- **Web Deployer**: Manages Git clone, npm install, and Vite build.
- **Security Engine**: Configures Certbot and VSFTPD.

## Components

### 1. Dynamic Brotli Compilation
To avoid version mismatch, the script will:
1. Extract the current Nginx version using `nginx -v`.
2. Download the matching source code.
3. Use `--with-compat` to ensure module compatibility.

### 2. Disk Space Optimization
With only 10GB of disk, the script will:
- Use `apt-get clean` and `apt-get autoremove`.
- Delete `/tmp/nginx-source` immediately after `make modules`.
- Build the React app and then potentially remove `node_modules` if disk space is critical (optional, configurable).

### 4. VM Performance & Stability
- **Swap Management**: Create a 2GB file at `/swapfile` with correct permissions (600) and add to `/etc/fstab`.
- **Sysctl Tuning**:
  - `net.core.somaxconn = 1024` (Handle more concurrent connections).
  - `net.ipv4.tcp_tw_reuse = 1` (Faster socket recycling).
  - `vm.swappiness = 10` (Prefer RAM over swap).
- **Auto-Updates**: Configure `unattended-upgrades` to only install security updates automatically to minimize stability risks.
- **Fail2Ban**: Define a jail for `sshd` and `vsftpd` with a 10-minute ban for 5 failed attempts.

## Data Models (Variables)
- `DOMAIN`: FQDN for the landing page.
- `EMAIL`: Contact email for Certbot.
- `GITHUB_REPO_URL`: Source code repository.
- `FTP_USER` / `FTP_PASS`: Credentials for FTP.

## Correctness Properties

### Property 1: Idempotency
*For any* component $C$, running $C$ twice on the same system state results in the same desired configuration without errors.
**Validates: Constraints C3**

### Property 2: Cleanup Integrity
*For any* temporary build artifact created in `/tmp`, the artifact SHALL be removed before script completion.
**Validates: Requirements R7.1**

### Property 3: Port Accessibility
*For any* required service (HTTP, HTTPS, SSH, FTP), the corresponding port SHALL be open in UFW after script execution.
**Validates: Requirements R6.2**

## Testability Analysis
- **R1.2 Validation**: Testable via script execution with missing arguments. (Example)
- **R3.2 Nginx Version Detection**: Testable by checking the regex output against `nginx -v`. (Property)
- **R4.1 SSL Setup**: Requires live domain; will implement dry-run check if possible, otherwise rely on log verification. (Edge-case)
- **R7.1 Disk Usage**: Testable by measuring `df -h` before and after script execution. (Property)
