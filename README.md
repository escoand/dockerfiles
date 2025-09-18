# Design Philosophy and Principles

This repository is designed to provide **lightweight, secure, and maintainable container-based services** using Podman and systemd. The goal is a server environment that requires minimal manual intervention while maintaining high reliability, security, and observability.

---

## Core Principles

### 1. **Immutability & Version Control**
- All container images are pinned to **specific versions** or digests.
- Updates are managed via **GitOps tools** (Quadit) and **Renovate**, ensuring reproducible deployments.
- No `latest` tags or uncontrolled image updates.

### 2. **Automated Management**
- Containers are managed as **systemd units (Podlets/Quadlets)** for automatic start, restart, and failure recovery.
- Healthchecks are defined to allow systemd to detect service health.
- Logging and monitoring are integrated with **systemd-journal** and **Dozzle**, providing simple but effective observability.

### 3. **Security by Default**
- Prefer **rootless Podman containers**.
- Minimize privileges: drop all unnecessary capabilities and run as non-root users when possible.
- Enforce **NoNewPrivileges**, SELinux/AppArmor, and container-specific security policies.
- Optional: image scanning (e.g., Trivy) in CI to catch vulnerabilities early.

### 4. **Resource Control & Isolation**
- CPU and memory limits are applied to prevent a single container from monopolizing host resources.
- Network exposure is minimized: only required ports are published, preferably via a reverse proxy.
- Containers are isolated to prevent lateral movement between services.

### 5. **Backup & Disaster Recovery**
- All persistent volumes are backed up using **restic** with remote storage.
- Restore procedures and integrity checks are part of operational routines.

### 6. **Simplicity & Maintainability**
- Avoid overly complex stacks (no ELK unless strictly needed).
- Use minimal tooling that integrates well with systemd and Podman.
- Focus on reproducibility and self-documenting configuration.

### 7. **Observability & Dashboard**
- Logs are centralized in **systemd-journal**, visualized with **Dozzle**.
- Metrics and status are optionally exposed via lightweight exporters (systemd-exporter, node-exporter, cAdvisor) for monitoring dashboards.
- Cockpit with Podman plugin can be used as a minimal, user-friendly system overview.

---

## Usage Guidelines

1. Always define **HealthCmd** for services exposing endpoints.  
2. Explicitly set **resource limits** in `.container` files.  
3. Use fixed **image versions or digests**.  
4. Run containers **rootless** wherever possible.  
5. Maintain **documentation and restore tests** for backups.  
6. Apply consistent **security practices** across all containers.  

---

By following these principles, this repository ensures **robust, secure, and low-maintenance containerized services**, suitable for production use with minimal operational overhead.
