# KRAFTY Automated VM Server Setup (AVMSS)

![Gen AI](https://img.shields.io/badge/Gen_AI-Powered-blue)
![Gemini 3](https://img.shields.io/badge/Gemini_3-Optimized-orange)
![VM](https://img.shields.io/badge/VM-Optimized-blue)
![Debian 12](https://img.shields.io/badge/Debian_12-Compatible-red)
![Automation](https://img.shields.io/badge/Automation-Full-green)

A professional-grade, automated setup script to transform a fresh Debian Bookworm VM into a secure, high-performance web server. Optimized for serving modern React/Vite landing pages with Nginx, Brotli compression, and automated SSL.

## Features

- **High Performance**: 2GB Swap file, tuned Sysctl network stack, and dynamic Brotli compression.
- **Hardened Security**: 
  - `Fail2Ban` for SSH/FTP brute-force protection.
  - `UFW` firewall restricted to essential ports.
  - `Unattended-upgrades` for automatic security patches.
  - Forced SSL/TLS for all connections (HTTPS and FTPS).
- **Automated SSL**: Integrated Certbot for Let's Encrypt certificates with built-in port conflict resolution and fallback modes.
- **Modern Stack**: Node.js 20, Nginx (Official Repo), and Git-driven deployment.
- **Build Resilience**: Automated fallback for TypeScript/Linting errors during the build process to ensure deployment success.
- **Resource Aware**: Aggressive cleanup of build artifacts and source code to stay within 10GB disk limits.

## 🚀 Getting Started

### 1. Prerequisites
- **DNS Setup**: Point your domain's **A Record** to your VM's External IP before running the script.
- **GitHub Token**: If your repository is private, generate a [Personal Access Token (Classic)](https://github.com/settings/tokens) with `repo` scope.
- **VM Specs**: Debian 12 (Bookworm), 2 vCPU, 8GB RAM, 10GB Disk.

### 2. Run the Setup Script
Connect to your VM via SSH and execute the following:

```bash
# Download the script
curl -O https://raw.githubusercontent.com/KraftyUX/avmss/main/startup-clean.sh
chmod +x startup-clean.sh

# Run with your configuration
sudo ./startup-clean.sh \
  --domain yourdomain.com \
  --repo https://github.com/your-user/your-landing-page.git \
  --email admin@yourdomain.com \
  --ftp-pass "your-secure-ftp-password" \
  --git-user "your-github-username" \
  --git-token "your-personal-access-token"
```

### 3. Verification
Once the script completes, your landing page will be live at `https://yourdomain.com`.
- **Logs**: Check `/var/log/krafty_setup.log` for setup details.
- **Health Check**: Run `sudo systemctl status nginx fail2ban vsftpd` to ensure all services are active.

## 🛠️ Connection & Management

### Secure FTP (FTPS)
To manage files remotely from your desktop:
- **Host**: Your VM IP or Domain
- **Protocol**: FTP over Explicit TLS/SSL
- **User**: `kraftyftp`
- **Password**: The password you provided during setup
- **Port**: 21

### Redeploying Your Site
The setup includes a helper command to redeploy your landing page whenever you push changes to your GitHub repository. It includes automated fallback building if standard type-checks fail.
```bash
sudo redeploy-landing-page
```

## 💎 Credits
This project was built with the assistance of the **Kilo Code** technical lead and **GEMINI 3 FLASH**, providing optimized server architecture and automated error resolution.

## License
MIT License. See [LICENSE](LICENSE) for more information.

---
**KRAFTYUX** | Made in EU
