# Requirements - Startup Script Optimization

## Overview
Optimize `startup-clean.sh` for a GCP VM (2 vCPU, 8GB RAM, 10GB Disk) to serve a React landing page with Nginx, Brotli, SSL, and Git-based deployment.

## Functional Requirements

### Configuration & Input
- **R1.1**: THE script SHALL accept configuration via environment variables or CLI arguments.
- **R1.2**: THE script SHALL validate that required variables (DOMAIN, GITHUB_REPO_URL) are provided before execution.
- **R1.3**: THE script SHALL use default values for optional configurations (FTP_USERNAME, NGINX_VERSION).

### System & Dependencies
- **R2.1**: THE script SHALL perform non-interactive package updates and installations.
- **R2.2**: THE script SHALL install `build-essential`, `git`, `curl`, `node.js` (v20), and `certbot`.

### Nginx & Brotli
- **R3.1**: THE script SHALL install the latest stable Nginx from the official Nginx repository.
- **R3.2**: THE script SHALL automatically detect the installed Nginx version for Brotli module compilation.
- **R3.3**: THE script SHALL compile `ngx_brotli` as a dynamic module.
- **R3.4**: THE script SHALL configure Nginx to use Brotli compression for static assets.

### SSL/TLS
- **R4.1**: WHEN a valid DOMAIN is provided, THE script SHALL obtain an SSL certificate via Certbot (Let's Encrypt).
- **R4.2**: THE script SHALL configure Nginx to redirect HTTP traffic to HTTPS.

### Deployment
- **R5.1**: THE script SHALL clone the specified GitHub repository to the deployment directory.
- **R5.2**: THE script SHALL install npm dependencies and run the production build.
- **R5.3**: THE script SHALL configure a Git `post-receive` hook to automate builds on repository updates.

### FTP & Security
- **R6.1**: THE script SHALL install and configure `vsftpd` with SSL/TLS enabled.
- **R6.2**: THE script SHALL configure UFW to allow traffic on ports 80, 443, 22, 21, and a passive FTP port range.
- **R6.3**: THE script SHALL create a dedicated FTP user with a home directory restricted to the deployment path.

### Resource Management
- **R7.1**: THE script SHALL remove Nginx source code and build artifacts after Brotli compilation to save disk space.
- **R7.2**: THE script SHALL perform `npm cache clean --force` and remove `node_modules` after the build if necessary to stay under the 10GB limit.

### VM Hardening & Optimization
- **R8.1**: THE script SHALL configure a 2GB swap file to handle memory spikes during builds.
- **R8.2**: THE script SHALL install and configure `fail2ban` to protect SSH and FTP from brute-force attacks.
- **R8.3**: THE script SHALL disable root SSH login and password authentication (enforcing SSH keys).
- **R8.4**: THE script SHALL enable `unattended-upgrades` for automatic security patches.
- **R8.5**: THE script SHALL apply `sysctl` optimizations for the network stack (increased max connections, faster TCP reuse).
- **R8.6**: THE script SHALL configure a weekly cron job for log rotation and system cleanup.
- **R8.7**: THE script SHALL ensure all services (Nginx, VSFTPD, Fail2Ban) are set to start on boot.

## Constraints
- **C1**: The script must run on Debian Bookworm.
- **C2**: Total disk usage during installation must not exceed 10GB.
- **C3**: The script must be idempotent (safe to run multiple times).
