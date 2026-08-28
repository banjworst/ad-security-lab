# Active Directory Security Hardening & Monitoring Lab

## Project Overview

A hands-on cybersecurity lab building and hardening an Active Directory environment on a home lab setup. The domain, security policies, and access controls are built and verified. Attack simulations (Kerberoasting, golden ticket, and others) are documented as a threat model but have not yet been executed against the lab — see Status below.

**Key Skills Demonstrated:**
- Active Directory administration and security hardening
- Security policy enforcement (password policies, account lockout)
- Privilege access management and group-based access control
- Threat modeling for common AD attack vectors (Brute Force, Privilege Escalation, Kerberoasting, Golden Tickets)
- Linux system administration
- Technical documentation

---

## Lab Architecture

```
M4 MacBook Air - UTM Virtualization
├─ Samba4 AD DC (192.168.64.4)
│  ├─ Domain: homelab.local
│  ├─ DNS: Active
│  ├─ Password policy: 12+ chars, 30-min lockout, 24 password history
│  ├─ Security groups: Domain_Admins_Restricted, Service_Accounts, Privileged_Users
│  └─ Test users: admin_user, service_account, regular_user
│
└─ Audit logging: Enabled for security monitoring
```

---

## Security Hardening Implemented

### 1. Password Policy Enforcement

Current policy settings:
- Minimum 12-character passwords
- Password history of 24 (prevents password reuse)
- Account lockout after 5 failed attempts
- 30-minute lockout duration
- 42-day maximum password age

**Mitigations:**
- Prevents weak credentials (12+ char minimum)
- Reduces brute force attack effectiveness
- Forces regular password changes
- Automatic account protection on suspicious activity

### 2. Privileged Access Management (PAM)

Security groups created:
- **Domain_Admins_Restricted**: Administrative users with full domain access
- **Service_Accounts**: Service account group for application services
- **Privileged_Users**: Users with elevated but not full admin privileges

**Principle of Least Privilege:**
- Regular users: No special privileges
- Service accounts: Limited to necessary permissions
- Admin users: Only added to admin groups when required
- All access changes logged

### 3. Test Users Created

Domain users for testing:
- **admin_user**: Member of Domain_Admins_Restricted and Privileged_Users
- **service_account**: Member of Service_Accounts and Privileged_Users
- **regular_user**: Standard user with no special privileges

---

## Attack Scenarios (Threat Model — Not Yet Executed)

The scenarios below are documented as a threat model with planned detection and mitigation approaches. They have **not yet been run against the lab environment** — no captured tool output, cracked hashes, or forged tickets exist yet. See ATTACK_SCENARIOS.md for the full write-up. Execution is the next phase of this project.

### Scenario 1: Brute Force Attack

**Scenario:** Attacker attempts repeated failed logins

**Planned mitigation:** Account lockout after 5 failed attempts, 30-minute lockout period

**Planned detection:** Event ID 4740 (Account locked out)

### Scenario 2: Privilege Escalation

**Scenario:** Non-privileged user attempts to execute admin commands

**Planned mitigation:** Group-based access control, least privilege enforcement

**Planned detection:** Event ID 4672 (Privilege assignment), failed command attempts logged

### Scenario 3: Kerberoasting (Credential Dumping)

**Scenario:** Attacker requests TGS tickets for service accounts and attempts to crack them offline

**Planned mitigation:** Strong passwords (12+ chars) for service accounts

**Planned detection:** Event ID 4769 (Kerberos ticket requested), unusual ticket request patterns

### Scenario 4: Golden Ticket Attack

**Scenario:** Attacker forges Kerberos Ticket Granting Tickets using a compromised KRBTGT hash

**Planned mitigation:** KRBTGT password rotation strategy, TGT monitoring

**Planned detection:** Unusual TGT creation patterns, TGT validity period monitoring

---

## Lab Results & Findings

### Verified Security Controls (Environment)

| Control | Status | Impact |
|---------|--------|--------|
| Password Policy Enforcement | Enabled | Prevents weak credentials |
| Account Lockout | 5 attempts / 30 min | Blocks brute force attacks |
| Privilege Separation | 3 security groups | Enforces least privilege |
| Password History | 24 previous passwords | Prevents password reuse |
| Password Expiration | 42 days | Forces regular changes |
| DNS Resolution | Functional | Domain operations enabled |

These controls are configured and verified in the running lab. The attack scenarios above are the planned next phase to validate them under simulated attack conditions.

---

## Tools & Technologies

- **Virtualization**: UTM (ARM64 support)
- **Domain Controller**: Samba4 (Linux-based AD)
- **Operating System**: Ubuntu Server 20.04+
- **Scripting**: Bash
- **Logging**: auditd
- **Monitoring**: samba-tool, ausearch

---

## Repository Structure

```
ad-security-lab/
├── README.md                    # Project overview
├── SETUP.md                     # Installation and configuration guide
├── ATTACK_SCENARIOS.md          # Detailed threat model and mitigations
├── LICENSE                      # MIT License
├── .gitignore                   # Git ignore rules
│
└── scripts/
    └── hardening.sh            # Security hardening commands
```

---

## Getting Started

### Prerequisites
- M1/M2/M3/M4 Mac (or any Linux system)
- UTM or similar virtualization platform
- Ubuntu Server 20.04+ VM
- 8GB RAM minimum, 100GB disk space

### Setup Instructions

See **SETUP.md** for detailed step-by-step installation and configuration.

---

## Detailed Documentation

- **SETUP.md**: Complete installation guide with all commands
- **ATTACK_SCENARIOS.md**: In-depth threat modeling, detection methods, and mitigation strategies

---

## Key Learnings

1. **Active Directory Security** - Real-world hardening practices and enterprise controls
2. **Attack Vectors** - Researching and modeling common AD attack methodologies
3. **Security Architecture** - Designing least-privilege access models
4. **Documentation** - Professional security lab writeup and threat analysis
5. **Problem-solving** - Working around Apple Silicon virtualization constraints

---

## What This Project Demonstrates

- Hands-on experience building and hardening a real AD environment
- Threat modeling from both offensive and defensive perspectives
- Professional security analysis and documentation
- Linux system administration and command-line proficiency
- Problem-solving and troubleshooting (especially on Apple Silicon constraints)

**Next step:** execute the documented attack scenarios (starting with Kerberoasting, using Impacket's GetUserSPNs.py) against the lab and capture real output, screenshots, and detection results.

---

## Resources & References

- MITRE ATT&CK Framework - Active Directory Attacks
- Microsoft Security Best Practices
- NIST Cybersecurity Framework
- Kerberos Security Documentation

---

## License

This project is open source and available under the MIT License.

---

**Last Updated**: August 2026
**Status**: Environment built & hardened. Attack simulations documented, execution in progress.
