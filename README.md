# Active Directory Security Hardening & Monitoring Lab

## Project Overview

A hands-on cybersecurity lab demonstrating **Active Directory security hardening, attack simulation, and threat detection** built on a home lab environment. This project combines offensive and defensive security practices to showcase real-world AD security challenges and mitigations.

**Key Skills Demonstrated:**
- Active Directory administration and security hardening
- Security policy enforcement (password policies, account lockout)
- Privilege access management and group-based access control
- Attack simulation (Brute Force, Privilege Escalation, Kerberoasting, Golden Tickets)
- Threat detection and incident response
- Linux system administration

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

## Attack Simulations & Mitigations

### Attack 1: Brute Force Attack

**Scenario:** Attacker attempts repeated failed logins

**Mitigation:** Account lockout after 5 failed attempts, 30-minute lockout period

**Detection:** Event ID 4740 (Account locked out)

**Result:** Attack stopped within seconds, suspicious activity logged

### Attack 2: Privilege Escalation

**Scenario:** Non-privileged user attempts to execute admin commands

**Mitigation:** Group-based access control, least privilege enforcement

**Detection:** Event ID 4672 (Privilege assignment), failed command attempts logged

**Result:** Access denied, escalation attempt documented

### Attack 3: Kerberoasting (Credential Dumping)

**Scenario:** Attacker requests TGS tickets for service accounts

**Mitigation:** Strong passwords (12+ chars) for service accounts

**Detection:** Event ID 4769 (Kerberos ticket requested), unusual ticket patterns

**Result:** Ticket requests monitored, strong passwords prevent successful cracking

### Attack 4: Golden Ticket Attack

**Scenario:** Attacker forges Kerberos Ticket Granting Tickets

**Mitigation:** KRBTGT password rotation strategy, TGT monitoring

**Detection:** Unusual TGT creation patterns, TGT validity period monitoring

**Result:** Detection rules configured, mitigation documented

---

## Lab Results & Findings

### Verified Security Controls

| Control | Status | Impact |
|---------|--------|--------|
| Password Policy Enforcement | Enabled | Prevents weak credentials |
| Account Lockout | 5 attempts / 30 min | Blocks brute force attacks |
| Privilege Separation | 3 security groups | Enforces least privilege |
| Password History | 24 previous passwords | Prevents password reuse |
| Password Expiration | 42 days | Forces regular changes |
| DNS Resolution | Functional | Domain operations enabled |

### Security Posture

- **Account Security**: Strong (12+ char minimum, history enforcement, lockout)
- **Access Control**: Strong (role-based groups, least privilege)
- **Monitoring**: Enabled (audit logging configured)
- **Threat Detection**: Configured (detection rules for each attack vector)

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
2. **Attack Vectors** - Understanding common AD attack methodologies
3. **Threat Detection** - Identifying and monitoring suspicious activity
4. **Security Architecture** - Designing least-privilege access models
5. **Documentation** - Professional security lab writeup and threat analysis

---

## What This Project Demonstrates

- Hands-on experience building and securing a real AD environment
- Deep security knowledge - both offensive and defensive perspectives
- Professional security analysis and documentation
- Linux system administration and command-line proficiency
- Problem-solving and troubleshooting (especially on Apple Silicon constraints)
- Security best practices and enterprise controls

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

**Last Updated**: March 2026  
**Status**: Complete & Tested
