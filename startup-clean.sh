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
    fi

    # 2. Sysctl Tuning
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

    # 3. Auto-Updates (Security only)
    log "Configuring unattended-upgrades..."
    sudo apt-get install -y unattended-upgrades
    sudo dpkg-reconfigure -plow unattended-upgrades

    # 4. Fail2Ban for SSH and VSFTPD
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

    # 5. Periodic Maintenance (Cron)
    log "Adding weekly maintenance cron job..."
    sudo bash -c "cat > /etc/cron.weekly/krafty-cleanup" << EOF
#!/bin/bash
apt-get autoremove -y
apt-get clean
journalctl --vacuum-time=7d
EOF
    sudo chmod +x /etc/cron.weekly/krafty-cleanup
}

# --- System Provisioning ---
install_dependencies() {
    log "Optimizing system and installing dependencies..."
    export DEBIAN_FRONTEND=noninteractive
    sudo apt-get update -y || error_exit "Failed to update package list."
    sudo apt-get install -y build-essential libpcre3 libpcre3-dev zlib1g zlib1g-dev \
        libssl-dev libbrotli-dev git curl gnupg2 ca-certificates lsb-release ufw \
        certbot python3-certbot-nginx vsftpd || error_exit "Failed to install dependencies."
}

# --- Firewall Setup ---
configure_firewall() {
    log "Configuring UFW firewall..."
    sudo ufw --force reset
    sudo ufw default deny incoming
    sudo ufw default allow outgoing
    sudo ufw allow 22/tcp
    sudo ufw allow 80/tcp
    sudo ufw allow 443/tcp
    sudo ufw allow 21/tcp
    sudo ufw allow 40000:40100/tcp
    sudo ufw --force enable || error_exit "Failed to enable UFW."
}

# --- Install Nginx ---
install_nginx() {
    log "Installing Nginx from official repository..."
    curl -fsSL https://nginx.org/keys/nginx_signing.key | gpg --dearmor | sudo tee /usr/share/keyrings/nginx-archive-keyring.gpg >/dev/null
    echo "deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] http://nginx.org/packages/debian $(lsb_release -cs) nginx" | sudo tee /etc/apt/sources.list.d/nginx.list
    sudo apt-get update -y
    sudo apt-get install -y nginx || error_exit "Failed to install Nginx."
}

# --- Clone and Compile Brotli Module ---
compile_brotli_module() {
    log "Dynamically compiling Brotli module..."
    
    # Detect Nginx version
    NGINX_VER=$(nginx -v 2>&1 | grep -oP 'nginx/\K[0-9.]+')
    log "Detected Nginx version: $NGINX_VER"

    cd /tmp || error_exit "Failed to navigate to /tmp."
    
    # Cleanup previous builds
    rm -rf ngx_brotli nginx-"$NGINX_VER"*

    git clone --recursive https://github.com/google/ngx_brotli.git || error_exit "Failed to clone ngx_brotli."
    
    wget "http://nginx.org/download/nginx-$NGINX_VER.tar.gz" || error_exit "Failed to download Nginx source."
    tar -xzvf "nginx-$NGINX_VER.tar.gz" > /dev/null
    cd "nginx-$NGINX_VER" || error_exit "Failed to navigate to Nginx source."

    # Configure with same parameters as installed nginx + compatibility
    ./configure --with-compat --add-dynamic-module=../ngx_brotli || error_exit "Failed to configure Nginx module."
    make modules || error_exit "Failed to compile Brotli modules."

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
    log "Configuring Nginx with Brotli and HTTPS readiness..."
    
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
    log "Obtaining SSL certificate via Certbot..."
    sudo certbot --nginx -d "$DOMAIN" --non-interactive --agree-tos -m "$EMAIL" --redirect || log "Certbot failed, will retry later or requires manual DNS."
}

# --- Install Node.js and Tooling ---
install_nodejs() {
    log "Installing Node.js 20..."
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
    sudo apt-get install -y nodejs || error_exit "Failed to install Node.js."
}

# --- Web Deployment & Build ---
deploy_webapp() {
    log "Deploying web application from $GITHUB_REPO_URL..."
    sudo mkdir -p "$DEPLOY_DIR"
    sudo chown "$USER:$USER" "$DEPLOY_DIR"
    
    if [ ! -d "$DEPLOY_DIR/.git" ]; then
        git clone "$GITHUB_REPO_URL" "$DEPLOY_DIR" || error_exit "Failed to clone repository."
    else
        cd "$DEPLOY_DIR" && git pull origin main
    fi

    cd "$DEPLOY_DIR"
    npm install || error_exit "npm install failed."
    npm run build || error_exit "npm build failed."
    
    # Optimization: remove cache and node_modules after build to save disk
    npm cache clean --force
    # sudo rm -rf node_modules # Optional: keep if needed for hooks
    log "Web application build complete."
}

# --- Configure Git Hooks ---
configure_git_hooks() {
    log "Configuring Git hooks for automation..."
    # Create a bare repo for local push if needed, but since we pull from GitHub:
    # We'll set up a simple script to trigger redeploy
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
    log "Configuring Secure FTP (VSFTPD)..."
    
    # Create FTP user if not exists
    if ! id "$FTP_USERNAME" &>/dev/null; then
        sudo useradd -m -s /bin/bash "$FTP_USERNAME"
        echo "$FTP_USERNAME:$FTP_PASSWORD" | sudo chpasswd
    fi

    # SSL Cert for FTP (Reuse Snakeoil for now or Certbot if possible)
    # For professional setup, we use the self-signed generated by vsftpd or certbot ones
    
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
    optimize_vm
    install_dependencies
    configure_firewall
    install_nginx
    compile_brotli_module
    configure_nginx
    install_nodejs
    deploy_webapp
    configure_git_hooks
    setup_ssl
    configure_ftp
    finalize_setup
}

main "$@"
