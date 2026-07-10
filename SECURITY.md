# SECURITY.md

## PARRALAX-AIHFTFUND Security Policy

### Version 1.0

---

## 1. Security Principles

1. **Zero Trust** — No component trusts another without verification
2. **Least Privilege** — Agents operate with minimum required permissions
3. **Defense in Depth** — Multiple layers of security controls
4. **Audit Everything** — All actions produce immutable receipts
5. **Secrets Never in Code** — All credentials managed via secure vaults

---

## 2. Authentication & Authorization

### API Access
- All API endpoints require authentication
- JWT tokens with short expiry (15 min access, 7 day refresh)
- Rate limiting per agent and per endpoint
- IP allowlisting for production execution

### Agent Authentication
- Each agent has a unique cryptographic identity
- Agent actions are signed with private keys
- Inter-agent communication requires mutual authentication

### Human Access
- Multi-factor authentication required
- Session timeout after 30 minutes of inactivity
- Privileged operations require re-authentication

---

## 3. Data Protection

### At Rest
- All databases encrypted (AES-256)
- API keys and credentials in HashiCorp Vault or equivalent
- Backup encryption with separate key management

### In Transit
- TLS 1.3 for all external communications
- mTLS for internal service-to-service
- WebSocket connections authenticated and encrypted

### Sensitive Data
- No credentials in source code, logs, or receipts
- PII handling compliant with applicable regulations
- Trading strategy parameters classified as confidential

---

## 4. Infrastructure Security

- Container isolation for each service
- Network segmentation between trading and management planes
- Regular security patches and dependency updates
- Immutable infrastructure (rebuild, don't patch)
- No SSH access to production — all changes through CI/CD

---

## 5. Incident Response

### Reporting
- Security issues: report privately to repository owner
- Do NOT open public issues for security vulnerabilities

### Response SLA
- Critical (active exploit): 1 hour response
- High (vulnerability): 24 hour response
- Medium: 7 day response
- Low: Next release cycle

---

## 6. Dependency Security

- Automated vulnerability scanning (Dependabot, Snyk)
- No dependencies with known critical CVEs in production
- Regular audit of transitive dependencies
- Lock files maintained and reviewed

---

## 7. Operational Security

- All deployments require signed commits
- Production secrets rotated quarterly
- Access logs retained for 90 days minimum
- Annual security review and penetration testing
