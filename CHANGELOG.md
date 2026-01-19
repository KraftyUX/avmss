# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-01-19

### Added
- **Dynamic Brotli Compilation**: Nginx module compilation tailored to the specific installed version.
- **VM Hardening**: 2GB swap file, sysctl performance tuning, and `unattended-upgrades`.
- **Security**: Fail2Ban, UFW lockdown, and forced SSL for HTTPS/FTPS.
- **Deployment**: Certbot integration and `redeploy-landing-page` helper script.
- **Documentation**: Comprehensive README, CLI Cheatsheet, contributing guidelines, and license.
- **Repository**: Initialized Git repository for version tracking.

### Changed
- Refactored `startup-clean.sh` to support CLI arguments and environment variables.
- Optimized Nginx configuration for security and high-performance React hosting.
