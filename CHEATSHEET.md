# KRAFTY Server Administration Cheatsheet

A production-ready reference for managing your optimized Debian Bookworm server.

## 🚀 Nginx Management & Brotli
| Command | Description |
|---|---|
| `sudo nginx -t` | Test Nginx configuration for syntax errors. |
| `sudo systemctl reload nginx` | Gracefully reload Nginx without dropping connections. |
| `sudo systemctl status nginx` | Check if Nginx is active and view recent errors. |
| `curl -I -H "Accept-Encoding: br" https://yourdomain.com` | Verify Brotli compression (look for `content-encoding: br`). |
| `nginx -V` | View Nginx build arguments and loaded modules. |

## ⚙️ System Optimization & Monitoring
| Command | Description |
|---|---|
| `htop` | Interactive process viewer (monitor CPU/RAM usage). |
| `free -h` | Monitor RAM and the **2GB swap file** usage. |
| `swapon --show` | Verify swap file status and priority. |
| `sysctl -a \| grep krafty` | Verify applied KRAFTY sysctl performance tweaks. |
| `df -h` | Monitor disk space (critical for the 10GB limit). |
| `sudo journalctl --vacuum-time=7d` | Manually clean up old system logs. |

## 🛡️ Security & Logs
| Command | Description |
|---|---|
| `sudo ufw status numbered` | View active firewall rules and port status. |
| `sudo fail2ban-client status sshd` | View blocked IPs and brute-force protection status. |
| `tail -f /var/log/krafty_setup.log` | Real-time tracking of the KRAFTY startup script. |
| `tail -f /var/log/nginx/error.log` | Monitor web server errors in real-time. |
| `sudo certbot certificates` | View SSL certificate status and expiration dates. |
| `sudo redeploy-landing-page` | Helper command to pull, build, and deploy latest code. |

## 🪟 TMUX: Session Persistence
*Use `Ctrl + b` as the prefix key.*

### Session Management
| Command | Description |
|---|---|
| `tmux` | Start a new session. |
| `tmux attach` | Re-attach to the last active session. |
| `tmux detach` | `Ctrl + b`, then `d`. Keep processes running in background. |
| `tmux ls` | List all active background sessions. |

### Window & Pane Control
| Key Combo | Description |
|---|---|
| `Ctrl + b`, `c` | Create a new window. |
| `Ctrl + b`, `n` / `p` | Move to Next / Previous window. |
| `Ctrl + b`, `"` | Split pane horizontally. |
| `Ctrl + b`, `%` | Split pane vertically. |
| `Ctrl + b`, `Arrow Keys` | Navigate between panes. |
| `Ctrl + b`, `x` | Kill the current pane. |
| `Ctrl + b`, `[` | Enter **Scroll Mode** (use arrows to scroll up, `q` to exit). |

## 📦 Deployment helper
| Path | Purpose |
|---|---|
| `/var/www/landing-page` | Primary deployment directory. |
| `/etc/nginx/conf.d/default.conf` | Domain-specific Nginx configuration. |
| `/usr/local/bin/redeploy-landing-page` | Custom build/deploy automation script. |
