# KRAFTY AVMSS: Complete User Journey Guide

This guide walks you through the entire lifecycle of setting up a professional web server using the **KRAFTY Automated VM Server Setup (AVMSS)**. 

---

## Phase 1: Infrastructure Provisioning

### 1.1 Choose Your Cloud Provider
AVMSS is optimized for **Debian 12 (Bookworm)**.
- **Recommended VM**: GCP `e2-standard-2` (2 vCPU, 8GB RAM).
- **Disk**: 10GB Balanced Persistent Disk.
- **Network**: You **must** enable "Allow HTTP traffic" and "Allow HTTPS traffic" in your instance settings.

### 1.2 DNS Preparation
Before running the script, point your Domain Name (e.g., `example.com`) to the **External IP** of your VM using an `A Record`.
- **Reason**: Certbot requires a valid DNS record to verify ownership and issue an SSL certificate.

---

## Phase 2: Server Initialization

### 2.1 Secure Connection
Connect to your fresh VM via SSH:
```bash
ssh -i ~/.ssh/your-key user@your-vm-ip
```

### 2.2 Download & Prepare
Fetch the KRAFTY setup script directly from the repository:
```bash
curl -O https://raw.githubusercontent.com/KraftyUX/avmss/main/startup-clean.sh
chmod +x startup-clean.sh
```

---

## Phase 3: The Automated Installation

### 3.1 Execute the Script
Run the script with your specific configuration. 
- **Fact**: The script uses `set -e`, meaning it will stop immediately if any step fails, preventing a "broken" partial installation.

```bash
sudo ./startup-clean.sh \
  --domain example.com \
  --repo https://github.com/your-user/your-react-app.git \
  --email admin@example.com \
  --ftp-pass "YourSecurePassword123!"
```

### 3.2 Behind the Scenes
As the script runs, it performs the following critical tasks:
1.  **Hardening**: Creates a **2GB swap file** to prevent OOM (Out of Memory) errors during `npm build`.
2.  **Network Tuning**: Applies `sysctl` tweaks to handle more concurrent TCP connections.
3.  **Brotli**: Compiles `ngx_brotli` specifically for your Nginx version to ensure maximum compression efficiency.
4.  **Deployment**: Clones your repo, runs `npm install`, and generates the production build in `/var/www/landing-page/dist`.

---

## Phase 4: Verification & Go-Live

### 4.1 Check Service Status
Once the script finishes, verify that everything is running smoothly:
```bash
# Check if Nginx is active
sudo systemctl status nginx

# Verify the Firewall is active and blocking ports
sudo ufw status
```

### 4.2 Verify Brotli Compression
Brotli provides ~20% better compression than Gzip for text assets. Verify it's working:
```bash
curl -I -H "Accept-Encoding: br" https://example.com
```
*Expected Output:* `content-encoding: br`

### 4.3 Browser Validation
Open your browser and navigate to `https://example.com`.
- **Observation**: You should see a locked padlock icon next to the URL, indicating that the **Certbot** automated SSL setup was successful.
- **Fact**: Nginx is now serving your static files directly from the `/dist` folder with optimized headers.

---

## Phase 5: Ongoing Management

### 5.1 Remote File Access
Use a client like FileZilla to connect via **FTPS** (FTP over TLS):
- **Protocol**: `FTP - File Transfer Protocol`
- **Encryption**: `Require explicit FTP over TLS`
- **Host**: `example.com`
- **User**: `kraftyftp`
- **Port**: `21`

### 5.2 Seamless Updates
When you push new code to your GitHub `main` branch, simply run the helper command on the server:
```bash
sudo redeploy-landing-page
```
This command pulls the latest code, rebuilds the React app, and reloads Nginx—all in one step.

---

## Troubleshooting Facts
- **Logs**: If the installation fails, always check `/var/log/krafty_setup.log`.
- **OOM Errors**: If `npm build` crashes, check `free -h`. The 2GB swap file should be active.
- **Port Blocked**: Ensure GCP/AWS firewall rules allow port `21` and the passive range `40000-40100` for FTP.
