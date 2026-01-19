# KRAFTY Automated Landing Page Setup

Automated environment setup script for high-performance React landing pages on Google Cloud Platform (Debian Bookworm).

## Features

- **Nginx & Brotli**: Dynamic compilation of Brotli modules for Nginx.
- **SSL/TLS**: Automated Let's Encrypt certificates via Certbot.
- **VM Optimization**: 2GB Swap, tuned Sysctl, and Fail2Ban hardening.
- **Security**: UFW configuration, VSFTPD with forced SSL.
- **Deployment**: Node.js 20, Git-based deployment with Vite build optimization.

## Usage

```bash
sudo ./startup-clean.sh \
  --domain yourdomain.com \
  --repo https://github.com/user/repo.git \
  --email admin@yourdomain.com \
  --ftp-pass "secure-password"
```

## Configuration Options

| Option | Description | Mandatory |
|---|---|---|
| `--domain` | The target FQDN for the landing page | Yes |
| `--repo` | GitHub repository URL | Yes |
| `--email` | Contact email for Certbot SSL | Yes |
| `--ftp-pass` | Password for the secure FTP user | Yes |
| `--ftp-user` | Custom FTP username (default: kraftyftp) | No |

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
