# Tasks - Startup Script Optimization

- [x] 1. Core Script Framework
  - [x] 1.1 Implement Argument Parsing & Environment Overrides
    - Support `--domain`, `--repo`, `--email`, `--ftp-user`, `--ftp-pass`
    - _Requirements: R1.1, R1.2_
  - [x] 1.2 Implement Logger & Global Error Handler
    - _Requirements: R1.3_

- [x] 2. System Provisioning
  - [x] 2.1 Optimized Apt Updates & Base Dependencies
    - Use `DEBIAN_FRONTEND=noninteractive`
    - _Requirements: R2.1, R2.2_
  - [x] 2.2 UFW Firewall Configuration
    - Open 80, 443, 22, 21, 40000-40100
    - _Requirements: R6.2_

- [x] 3. Nginx & Brotli
  - [x] 3.1 Official Nginx Repository Setup
    - _Requirements: R3.1_
  - [x] 3.2 Dynamic Brotli Compilation Engine
    - Detect version, download source, compile, install
    - _Requirements: R3.2, R3.3, R7.1_
  - [x] 3.3 Optimized Nginx Configuration
    - Include Brotli, Security headers, and SSL placeholder
    - _Requirements: R3.4_

- [x] 4. Web Deployment
  - [x] 4.1 Node.js & Tooling Installation
    - _Requirements: R2.2_
  - [x] 4.2 Git Clone & Build Pipeline
    - Implement `npm install` and `npm run build`
    - _Requirements: R5.1, R5.2, R7.2_
  - [x] 4.3 Git post-receive hook automation
    - _Requirements: R5.3_

- [x] 5. SSL & FTP
  - [x] 5.1 Certbot SSL Integration
    - _Requirements: R4.1, R4.2_
  - [x] 5.2 VSFTPD SSL Configuration
    - Secure FTP setup with dedicated user
    - _Requirements: R6.1, R6.3_

- [x] 6. VM Optimization & Hardening
  - [x] 6.1 Implement Swap File (2GB)
    - _Requirements: R8.1_
  - [x] 6.2 Sysctl Tuning & Auto-Updates
    - _Requirements: R8.4, R8.5_
  - [x] 6.3 Fail2Ban & SSH Security
    - _Requirements: R8.2, R8.3_
  - [x] 6.4 Periodic Maintenance (Cron)
    - _Requirements: R8.6_

- [x] 7. Finalization
  - [x] 7.1 Cleanup & Health Check
    - Verify services are running, delete logs if successful
    - _Requirements: R7.1_
