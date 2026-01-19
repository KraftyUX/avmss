#!/bin/bash

# Script: Automated KRAFTY Environment Setup (Optimized)
# Author: KRAFTY
# Description: Professional Nginx setup with Brotli, Certbot, Node.js, Git, and Secure FTP.
# Designed for: GCP VM (2 vCPU, 8GB RAM, 10GB Disk)

set -e # Exit on error

# --- Defaults ---
LOG_FILE="/var/log/krafty_setup.log"
DEPLOY_DIR="/var/www/landing-page"
FTP_USERNAME="kraftyftp"
FTP_PASS_RANGE="40000-40100"
NGINX_MODULES_DIR="/etc/nginx/modules"

# --- Usage ---
usage() {
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  --domain DOMAIN        (Required) Target domain name"
    echo "  --repo URL             (Required) GitHub repository URL"
    echo "  --email EMAIL          (Required) Email for Certbot SSL"
    echo "  --ftp-user USERNAME    (Optional) FTP username (default: $FTP_USERNAME)"
    echo "  --ftp-pass PASSWORD    (Required) FTP password"
    echo "  --git-user USERNAME    (Optional) GitHub username"
    echo "  --git-token TOKEN      (Optional) GitHub Personal Access Token"
    exit 1
}

# --- Argument Parsing ---
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --domain) DOMAIN="$2"; shift ;;
        --repo) GITHUB_REPO_URL="$2"; shift ;;
        --email) EMAIL="$2"; shift ;;
        --ftp-user) FTP_USERNAME="$2"; shift ;;
        --ftp-pass) FTP_PASSWORD="$2"; shift ;;
        --git-user) GIT_USER="$2"; shift ;;
        --git-token) GIT_TOKEN="$2"; shift ;;
        *) echo "Unknown parameter: $1"; usage ;;
    esac
    shift
done

# --- Environment Overrides ---
DOMAIN=${DOMAIN:-$ENV_DOMAIN}
GITHUB_REPO_URL=${GITHUB_REPO_URL:-$ENV_REPO_URL}
EMAIL=${EMAIL:-$ENV_EMAIL}
FTP_USERNAME=${FTP_USERNAME:-$ENV_FTP_USER}
FTP_PASSWORD=${FTP_PASSWORD:-$ENV_FTP_PASS}

# --- Validation ---
if [[ -z "$DOMAIN" || -z "$GITHUB_REPO_URL" || -z "$EMAIL" || -z "$FTP_PASSWORD" ]]; then
    echo "ERROR: Missing required arguments."
    usage
fi

# --- Logging Function ---
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | sudo tee -a "$LOG_FILE"
}

# --- Error Handling ---
error_exit() {
    log "CRITICAL ERROR: $1"
    exit 1
}

log "Starting KRAFTY environment setup for $DOMAIN..."

# --- VM Optimization (Swap, Sysctl, Hardening) ---
optimize_vm() {
    log "Optimizing VM performance and hardening..."

    # 1. Create Swap File (2GB)
    if [ ! -f /swapfile ]; then
        log "Creating 2GB swap file..."
        sudo fallocate -l 2G /swapfile || sudo dd if=/dev/zero of=/swapfile bs=1M count=2048
        sudo chmod 600 /swapfile
        sudo mkswap /swapfile
        sudo swapon /swapfile
        echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
    else
        log "Swap file already exists. Skipping."
    fi

    # 2. Sysctl Tuning
    if [ ! -f /etc/sysctl.d/99-krafty-optimize.conf ]; then
        log "Applying sysctl network optimizations..."
        sudo bash -c "cat > /etc/sysctl.d/99-krafty-optimize.conf" << EOF
net.core.somaxconn = 1024
net.ipv4.tcp_tw_reuse = 1
net.ipv4.ip_local_port_range = 1024 65535
net.ipv4.tcp_max_syn_backlog = 2048
net.ipv4.tcp_fin_timeout = 15
vm.swappiness = 10
EOF
        sudo sysctl -p /etc/sysctl.d/99-krafty-optimize.conf
    else
        log "Sysctl optimizations already applied. Skipping."
    fi

    # 3. Auto-Updates (Security only)
    if ! dpkg -s unattended-upgrades &>/dev/null; then
        log "Configuring unattended-upgrades..."
        sudo apt-get install -y unattended-upgrades
        sudo dpkg-reconfigure -plow unattended-upgrades
    else
        log "Unattended-upgrades already installed. Skipping."
    fi

    # 4. Fail2Ban for SSH and VSFTPD
    if ! dpkg -s fail2ban &>/dev/null; then
        log "Installing and configuring Fail2Ban..."
        sudo apt-get install -y fail2ban
        sudo bash -c "cat > /etc/fail2ban/jail.local" << EOF
[DEFAULT]
bantime = 10m
findtime = 10m
maxretry = 5

[sshd]
enabled = true

[vsftpd]
enabled = true
port = ftp,ftp-data,ftps,ftps-data
logpath = /var/log/vsftpd.log
EOF
        sudo systemctl restart fail2ban
    else
        log "Fail2Ban already installed. Skipping."
    fi

    # 5. Periodic Maintenance (Cron)
    if [ ! -f /etc/cron.weekly/krafty-cleanup ]; then
        log "Adding weekly maintenance cron job..."
        sudo bash -c "cat > /etc/cron.weekly/krafty-cleanup" << EOF
#!/bin/bash
apt-get autoremove -y
apt-get clean
journalctl --vacuum-time=7d
EOF
        sudo chmod +x /etc/cron.weekly/krafty-cleanup
    else
        log "Maintenance cron job already exists. Skipping."
    fi
}

# --- System Provisioning ---
install_dependencies() {
    log "Optimizing system and installing dependencies..."
    export DEBIAN_FRONTEND=noninteractive
    
    # Check for core dependencies
    local deps=(build-essential libpcre3 libpcre3-dev zlib1g zlib1g-dev libssl-dev libbrotli-dev git curl gnupg2 ca-certificates lsb-release ufw certbot python3-certbot-nginx vsftpd)
    local to_install=()
    
    for dep in "${deps[@]}"; do
        if ! dpkg -s "$dep" &>/dev/null; then
            to_install+=("$dep")
        fi
    done

    if [ ${#to_install[@]} -ne 0 ]; then
        log "Installing missing dependencies: ${to_install[*]}"
        sudo apt-get update -y
        sudo apt-get install -y "${to_install[@]}" || error_exit "Failed to install dependencies."
    else
        log "All base dependencies are already installed."
    fi
}

# --- Firewall Setup ---
configure_firewall() {
    log "Configuring UFW firewall..."
    
    if ! command -v ufw &>/dev/null; then
        sudo apt-get install -y ufw
    fi

    if sudo ufw status | grep -q "Status: active"; then
        log "UFW is already active. Checking rules..."
    else
        sudo ufw --force reset
        sudo ufw default deny incoming
        sudo ufw default allow outgoing
        sudo ufw allow 22/tcp
        sudo ufw allow 80/tcp
        sudo ufw allow 443/tcp
        sudo ufw allow 21/tcp
        sudo ufw allow 40000:40100/tcp
        sudo ufw --force enable || error_exit "Failed to enable UFW."
    fi
}

# --- Install Nginx ---
install_nginx() {
    if command -v nginx &>/dev/null; then
        log "Nginx is already installed. Skipping installation."
        return
    fi

    log "Installing Nginx from official repository..."
    log "Adding Nginx signing key..."
    curl -fsSL https://nginx.org/keys/nginx_signing.key | gpg --dearmor | sudo tee /usr/share/keyrings/nginx-archive-keyring.gpg >/dev/null
    log "Adding Nginx repository to sources list..."
    echo "deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] http://nginx.org/packages/debian $(lsb_release -cs) nginx" | sudo tee /etc/apt/sources.list.d/nginx.list
    log "Running apt-get update..."
    sudo apt-get update -y
    log "Running apt-get install nginx..."
    # Adding force-confold to prevent interactive prompts for config files
    sudo apt-get install -y -o Dpkg::Options::="--force-confold" nginx || error_exit "Failed to install Nginx."
    log "Nginx installation command finished."
}

# --- Clone and Compile Brotli Module ---
compile_brotli_module() {
    # Detect Nginx version
    log "Checking Nginx version..."
    
    log "Path to nginx: $(which nginx)"
    log "Nginx binary permissions: $(ls -l $(which nginx))"

    # Debug: Try to get raw output with a timeout
    log "Executing 'nginx -v' with 10s timeout..."
    if ! RAW_NGINX_V=$(timeout 10s nginx -v 2>&1); then
        log "WARNING: 'nginx -v' timed out or failed. Attempting to get version from package manager instead."
        RAW_NGINX_V=$(dpkg -s nginx | grep Version)
    fi
    log "Raw Nginx version output: $RAW_NGINX_V"
    
    # Extract version (supports both nginx -v output and dpkg output)
    NGINX_VER=$(echo "$RAW_NGINX_V" | grep -oP '[0-9]+\.[0-9]+\.[0-9]+' | head -n 1)
    log "Detected Nginx version: $NGINX_VER"

    if [[ -z "$NGINX_VER" ]]; then
        error_exit "Could not detect Nginx version from output: $RAW_NGINX_V"
    fi

    if [ -f "$NGINX_MODULES_DIR/ngx_http_brotli_filter_module.so" ]; then
        log "Brotli modules already exist. Skipping compilation."
        return
    fi

    log "Dynamically compiling Brotli module..."

    cd /tmp || error_exit "Failed to navigate to /tmp."
    
    # Cleanup previous builds
    rm -rf ngx_brotli nginx-"$NGINX_VER"*

    log "Cloning ngx_brotli repository (recursive)..."
    git clone --recursive https://github.com/google/ngx_brotli.git || error_exit "Failed to clone ngx_brotli."
    
    log "Downloading Nginx source version $NGINX_VER..."
    wget "http://nginx.org/download/nginx-$NGINX_VER.tar.gz" || error_exit "Failed to download Nginx source."
    log "Extracting Nginx source..."
    tar -xzvf "nginx-$NGINX_VER.tar.gz" > /dev/null
    cd "nginx-$NGINX_VER" || error_exit "Failed to navigate to Nginx source."

    log "Configuring Brotli module build..."
    # Configure with same parameters as installed nginx + compatibility
    ./configure --with-compat --add-dynamic-module=../ngx_brotli || error_exit "Failed to configure Nginx module."
    log "Starting compilation of modules (make modules)..."
    make modules || error_exit "Failed to compile Brotli modules."

    log "Moving compiled modules to $NGINX_MODULES_DIR..."
    sudo mkdir -p "$NGINX_MODULES_DIR"
    sudo cp objs/ngx_http_brotli_filter_module.so "$NGINX_MODULES_DIR"
    sudo cp objs/ngx_http_brotli_static_module.so "$NGINX_MODULES_DIR"
    
    # Immediate cleanup to save disk space
    cd /tmp
    rm -rf ngx_brotli nginx-"$NGINX_VER"*
    log "Brotli compilation complete and source code cleaned up."
}

# --- Configure Nginx ---
configure_nginx() {
    if [ -f /etc/nginx/nginx.conf.bak ]; then
        log "Nginx already configured. Skipping."
        return
    fi

    log "Configuring Nginx with Brotli and HTTPS readiness..."
    sudo cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.bak

    sudo bash -c "cat > /etc/nginx/nginx.conf" << EOF
user www-data;
worker_processes auto;
pid /run/nginx.pid;

load_module $NGINX_MODULES_DIR/ngx_http_brotli_filter_module.so;
load_module $NGINX_MODULES_DIR/ngx_http_brotli_static_module.so;

events {
    worker_connections 1024;
}

http {
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    types_hash_max_size 2048;
    server_tokens off;

    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    access_log /var/log/nginx/access.log;
    error_log /var/log/nginx/error.log;

    gzip on;
    brotli on;
    brotli_static on;
    brotli_comp_level 6;
    brotli_types text/plain text/css application/javascript application/json image/svg+xml;

    include /etc/nginx/conf.d/*.conf;
}
EOF

    sudo bash -c "cat > /etc/nginx/conf.d/default.conf" << EOF
server {
    listen 80;
    server_name $DOMAIN;

    location / {
        root $DEPLOY_DIR/dist;
        index index.html;
        try_files \$uri \$uri/ /index.html;
    }

    location ~* \.(?:ico|css|js|gif|jpe?g|png|woff2?|eot|otf|ttf|svg)$ {
        root $DEPLOY_DIR/dist;
        expires 6M;
        access_log off;
        add_header Cache-Control "public";
    }
}
EOF
}

# --- SSL Setup ---
setup_ssl() {
    if sudo certbot certificates | grep -q "$DOMAIN"; then
        log "SSL certificate for $DOMAIN already exists. Skipping."
        return
    fi

    log "Obtaining SSL certificate via Certbot..."
    sudo certbot --nginx -d "$DOMAIN" --non-interactive --agree-tos -m "$EMAIL" --redirect || log "Certbot failed, will retry later or requires manual DNS."
}

# --- Install Node.js and Tooling ---
install_nodejs() {
    if command -v node &>/dev/null; then
        log "Node.js is already installed. Skipping."
        return
    fi

    log "Installing Node.js 20..."
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
    sudo apt-get install -y nodejs || error_exit "Failed to install Node.js."
}

# --- Web Deployment & Build ---
deploy_webapp() {
    log "Deploying web application from $GITHUB_REPO_URL..."
    
    local auth_url="$GITHUB_REPO_URL"
    
    # If git credentials provided, inject them into the URL
    if [[ -n "$GIT_USER" && -n "$GIT_TOKEN" ]]; then
        log "Using provided GitHub credentials for authentication..."
        # Remove https:// prefix if exists to inject credentials
        local base_url="${GITHUB_REPO_URL#https://}"
        auth_url="https://${GIT_USER}:${GIT_TOKEN}@${base_url}"
    elif [[ "$GITHUB_REPO_URL" == git@github.com:* ]]; then
        log "SSH URL detected. Ensuring github.com is in known_hosts..."
        mkdir -p ~/.ssh
        ssh-keyscan -t rsa github.com >> ~/.ssh/known_hosts 2>/dev/null
    fi

    sudo mkdir -p "$DEPLOY_DIR"
    sudo chown "$USER:$USER" "$DEPLOY_DIR"
    
    if [ ! -d "$DEPLOY_DIR/.git" ]; then
        log "Cloning repository..."
        # If we have credentials, we use GIT_TERMINAL_PROMPT=0 to ensure it fails fast on bad creds
        # If no credentials, we allow prompting (which might hang if not in a real TTY)
        if [[ -n "$GIT_TOKEN" ]]; then
            GIT_TERMINAL_PROMPT=0 git clone "$auth_url" "$DEPLOY_DIR" || error_exit "Failed to clone repository. \nIMPORTANT: GitHub now requires a 'Personal Access Token' (Classic) with 'repo' scope, NOT your account password. \nPlease verify your token at: https://github.com/settings/tokens"
        else
            log "WARNING: No GitHub credentials provided. The script may hang waiting for a prompt if the repo is private."
            git clone "$auth_url" "$DEPLOY_DIR" || error_exit "Failed to clone repository."
        fi
    else
        log "Repository already exists. Updating..."
        cd "$DEPLOY_DIR"
        if [[ -n "$GIT_TOKEN" ]]; then
            # Update remote URL to include token if needed
            git remote set-url origin "$auth_url"
            GIT_TERMINAL_PROMPT=0 git pull origin main || log "Git pull failed."
        else
            git pull origin main || log "Git pull failed."
        fi
    fi

    cd "$DEPLOY_DIR"
    # Only install if node_modules missing or package.json changed
    if [ ! -d "node_modules" ]; then
        log "Running npm install..."
        npm install || error_exit "npm install failed."
    fi
    
    log "Running npm build..."
    npm run build || error_exit "npm build failed."
    
    # Optimization: remove cache after build
    npm cache clean --force
    log "Web application build complete."
}

# --- Configure Git Hooks ---
configure_git_hooks() {
    if [ -f /usr/local/bin/redeploy-landing-page ]; then
        log "Deployment helper already exists. Skipping."
        return
    fi

    log "Configuring Git hooks for automation..."
    sudo bash -c "cat > /usr/local/bin/redeploy-landing-page" << EOF
#!/bin/bash
cd $DEPLOY_DIR
git pull origin main
npm install
npm run build
sudo systemctl reload nginx
EOF
    sudo chmod +x /usr/local/bin/redeploy-landing-page
}

# --- Configure VSFTPD (Secure FTP) ---
configure_ftp() {
    if [ -f /etc/vsftpd.conf.bak ]; then
        log "FTP already configured. Skipping."
        return
    fi

    log "Configuring Secure FTP (VSFTPD)..."
    sudo cp /etc/vsftpd.conf /etc/vsftpd.conf.bak
    
    # Create FTP user if not exists
    if ! id "$FTP_USERNAME" &>/dev/null; then
        sudo useradd -m -s /bin/bash "$FTP_USERNAME"
        echo "$FTP_USERNAME:$FTP_PASSWORD" | sudo chpasswd
    fi

    sudo bash -c "cat > /etc/vsftpd.conf" << EOF
listen=YES
listen_ipv6=NO
anonymous_enable=NO
local_enable=YES
write_enable=YES
local_umask=022
dirmessage_enable=YES
use_localtime=YES
xferlog_enable=YES
connect_from_port_20=YES
chroot_local_user=YES
allow_writeable_chroot=YES

# SSL settings
ssl_enable=YES
allow_anon_ssl=NO
force_local_data_ssl=YES
force_local_logins_ssl=YES
ssl_tlsv1=YES
ssl_sslv2=NO
ssl_sslv3=NO
require_ssl_reuse=NO
ssl_ciphers=HIGH

# Passive Mode configuration for GCP
pasv_enable=YES
pasv_min_port=40000
pasv_max_port=40100

rsa_cert_file=/etc/ssl/certs/ssl-cert-snakeoil.pem
rsa_private_key_file=/etc/ssl/private/ssl-cert-snakeoil.key
EOF

    sudo systemctl restart vsftpd || error_exit "Failed to restart VSFTPD."
    log "FTP configured with SSL and Passive Mode ($FTP_PASS_RANGE)."
}

# --- Health Check & Finalize ---
finalize_setup() {
    log "Performing final health checks..."
    
    # Check Nginx
    sudo nginx -t || error_exit "Nginx configuration invalid."
    sudo systemctl restart nginx
    
    # Clean up APT
    sudo apt-get autoremove -y
    sudo apt-get clean
    
    log "Setup completed successfully."
    log "Landing page should be live at: http://$DOMAIN (or https if Certbot succeeded)"
}

# --- Main Execution ---
main() {
    log "Step 1: Optimizing VM..."
    optimize_vm
    log "Step 2: Installing dependencies..."
    install_dependencies
    log "Step 3: Configuring firewall..."
    configure_firewall
    log "Step 4: Installing Nginx..."
    install_nginx
    log "Step 5: Compiling Brotli module..."
    compile_brotli_module
    log "Step 6: Configuring Nginx..."
    configure_nginx
    log "Step 7: Installing Node.js..."
    install_nodejs
    log "Step 8: Deploying webapp..."
    deploy_webapp
    log "Step 9: Configuring Git hooks..."
    configure_git_hooks
    log "Step 10: Setting up SSL..."
    setup_ssl
    log "Step 11: Configuring FTP..."
    configure_ftp
    log "Step 12: Finalizing setup..."
    finalize_setup
}

main "$@"
