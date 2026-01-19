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
- **Automated SSL**: Integrated Certbot for Let's Encrypt certificates.
- **Modern Stack**: Node.js 20, Nginx (Official Repo), and Git-driven deployment.
- **Resource Aware**: Aggressive cleanup of build artifacts and source code to stay within 10GB disk limits.

## 🚀 Getting Started

### 1. Provision Your VM
- OS: **Debian 12 (Bookworm)**
- Suggested Specs: 2 vCPU, 8GB RAM, 10GB Disk (GCP e2-standard-2 or similar).
- Network: Ensure HTTP (80) and HTTPS (443) are allowed in your cloud provider's firewall.

### 2. Run the Setup Script
Connect to your VM via SSH and execute the following:

```bash
# Download the script
curl -O https://raw.githubusercontent.com/your-username/krafty-server-setup/main/startup-clean.sh
chmod +x startup-clean.sh

# Run with your configuration
sudo ./startup-clean.sh \
  --domain yourdomain.com \
  --repo https://github.com/your-user/your-landing-page.git \
  --email admin@yourdomain.com \
  --ftp-pass "your-secure-ftp-password"
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
- **User**: `kraftyftp` (or your custom user)
- **Password**: The password you provided during setup
- **Port**: 21

### SSH
The server is configured for standard SSH access. For enhanced security, it is recommended to use SSH keys:
```bash
ssh -i /path/to/your/key user@your-domain.com
```

### Redeploying Your Site
The setup includes a helper command to redeploy your landing page whenever you push changes to your GitHub repository:
```bash
sudo redeploy-landing-page
```

## 💎 Credits
This project was built with the assistance of the **GEMINI 3 FLASH** model, which provided core code generation and optimization for the KRAFTY server environment.

## License
MIT License. See [LICENSE](LICENSE) for more information.

---
**KRAFTYUX** | Made in EU
