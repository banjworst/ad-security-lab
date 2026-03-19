# Active Directory Security Hardening & Monitoring Lab

## Project Overview

A hands-on cybersecurity lab demonstrating **Active Directory security hardening, attack simulation, and threat detection** on a home lab environment. This project combines offensive and defensive security practices to showcase real-world AD security challenges and mitigations.

**Key Skills Demonstrated:**
- Active Directory administration and security hardening
- Security policy enforcement (password policies, account lockout)
- Audit logging and event monitoring
- Attack simulation (Brute Force, Privilege Escalation, Kerberoasting)
- Threat detection and incident response
- Python scripting for security automation

---

## Lab Architecture

```
┌─────────────────────────────────────────────────────┐
│          M4 MacBook Air - UTM Virtualization        │
├─────────────────────────────────────────────────────┤
│                                                     │
│  ┌──────────────────┐      ┌──────────────────┐   │
│  │   Samba4 AD DC   │      │  Windows 10 ARM  │   │
│  │  (192.168.64.4)  │◄────►│  (Optional)      │   │
│  │                  │      │                  │   │
│  │ • Domain: home   │      │ • Domain joined  │   │
│  │   lab.local      │      │ • Domain user    │   │
│  │ • DNS: Active    │      │ • Policy applied │   │
│  │ • Audit logging  │      │                  │   │
│  │ • 12+ char pwd   │      │                  │   │
│  │ • Account lockout│      │                  │   │
│  └──────────────────┘      └──────────────────┘   │
│                                                     │
└─────────────────────────────────────────────────────┘
```

---

## Security Hardening Implemented

### **1. Password Policy Enforcement**
```bash
sudo samba-tool domain passwordsettings set \
  --min-pwd-length=12 \
  --pwd-history-length=5 \
  --account-lockout-threshold=5 \
  --account-lockout-duration=30
```

**Mitigations:**
- Minimum 12-character passwords (prevents weak credentials)
- Password history of 5 (prevents password reuse)
- Account lockout after 5 failed attempts (brute force protection)
- 30-minute lockout duration (slows attackers)

### **2. Privileged Access Management (PAM)**
```bash
# Create security groups with restricted access
sudo samba-tool group add "Domain_Admins_Restricted"
sudo samba-tool group add "Service_Accounts"
sudo samba-tool group add "Privileged_Users"
```

**Principle of Least Privilege:**
- Separate admin accounts from regular users
- Service accounts isolated from user accounts
- Privileged operations logged and monitored

### **3. Audit Logging & Monitoring**
```bash
sudo auditctl -w /var/lib/samba/private/sam.ldb -p wa -k samba_changes
```

**Event Monitoring:**
- Event ID 4740: Account lockout (brute force detection)
- Event ID 4672: Special privileges assigned (escalation detection)
- Event ID 4769: Kerberos ticket requested (Kerberoasting detection)

---

## Attack Simulations & Mitigations

### **Attack 1: Brute Force Attack**
**Scenario:** Attacker attempts repeated failed logins

**Detection:**
```
Event ID 4740: Account locked out
Threshold: 5 failed attempts within 15 minutes
```

**Mitigation:**
- Account lockout policy (enforced)
- Monitoring for repeated failed attempts
- Admin notification on suspicious activity

### **Attack 2: Privilege Escalation**
**Scenario:** Non-privileged user attempts to execute admin commands

**Detection:**
```
Event ID 4672: Special privileges assigned to new logon
Event ID 4663: Unauthorized file/registry access attempts
```

**Mitigation:**
- Segregated admin groups
- Command auditing for privileged operations
- Regular privilege review

### **Attack 3: Kerberoasting (Credential Dumping)**
**Scenario:** Attacker requests TGS tickets for service accounts to crack offline

**Detection:**
```
Event ID 4769: Kerberos ticket requested (TGS-REQ)
Monitor for: Unusual service account ticket requests
```

**Mitigation:**
- Strong passwords for service accounts (12+ chars, enforced)
- Service Principal Name (SPN) scanning and hardening
- Monitoring for suspicious ticket requests
- Consider using managed service accounts

---

## Lab Results & Findings

### **Baseline Metrics**
| Metric | Value | Status |
|--------|-------|--------|
| Password Policy Enforcement | Enabled | Complete|
| Account Lockout | 5 attempts / 30 min | Complete|
| Audit Logging | Active | Complete |
| Privileged Group Separation | 3 groups | Complete |
| DNS Resolution | Functional | Complete |

### **Security Posture**
- **Account Security**: Strong (12+ char min, history, lockout)
- **Access Control**: Strong (role-based groups)
- **Monitoring**: Enabled (audit logging active)
- **Threat Detection**: Configured (event monitoring)

---

## Tools & Technologies

- **Virtualization**: UTM (ARM64)
- **Domain Controller**: Samba4 (Linux-based AD alternative)
- **Operating System**: Ubuntu Server 20.04+
- **Scripting**: Python 3
- **Logging**: auditd
- **Monitoring**: samba-tool commands

---

## Repository Structure

```
ad-security-lab/
├── README.md                          # This file
├── SETUP.md                          # Installation & setup guide
├── ATTACK_SCENARIOS.md               # Detailed attack descriptions
├── scripts/
│   ├── ad_security_lab.py           # Attack simulation & detection
│   ├── hardening.sh                 # Security hardening script
│   ├── audit_logging.sh             # Audit log setup
│   └── user_provisioning.py         # Automated user creation
├── configs/
│   ├── password_policy.conf         # Password policy settings
│   ├── audit_rules.txt              # Audit logging rules
│   └── group_policies.txt           # Group policy configurations
├── documentation/
│   ├── THREAT_MODEL.md              # Identified threats
│   ├── DETECTION_GUIDE.md           # How to detect each attack
│   └── MITIGATION_STRATEGIES.md     # Applied mitigations
└── screenshots/
    ├── samba_users_list.png
    ├── audit_logs.png
    ├── policy_enforcement.png
    └── group_membership.png
```

---

## Getting Started

### **Prerequisites**
- M1/M2/M3/M4 Mac (or any Linux system)
- UTM or similar virtualization platform
- Ubuntu Server 20.04+ VM
- 8GB RAM minimum, 100GB disk space

### **Quick Start**
```bash
# 1. Clone repository
git clone https://github.com/yourusername/ad-security-lab.git
cd ad-security-lab

# 2. Review setup documentation
cat SETUP.md

# 3. Run hardening script
chmod +x scripts/hardening.sh
sudo ./scripts/hardening.sh

# 4. Run security lab simulation
python3 scripts/ad_security_lab.py
```

### **Detailed Setup**
See [SETUP.md](SETUP.md) for step-by-step installation instructions.

---

## 📝 Key Learnings

1. **Active Directory Security** — Real-world hardening practices
2. **Attack Simulation** — Understanding attacker methodologies
3. **Threat Detection** — Identifying and responding to security events
4. **Security Automation** — Scripting security tasks and monitoring
5. **Documentation** — Professional security lab writeup

---

## 📄 License

This project is open source and available under the MIT License.

---

## About the Author

Cybersecurity enthusiast building hands-on labs to develop real-world security skills. This project demonstrates practical implementation of AD security hardening and threat detection.

**Skills:**
- Active Directory Administration
- Linux System Administration
- Python/Bash Scripting
- Security Hardening & Auditing
- Threat Detection & Response

---

## Contact

- **GitHub**: [https://github.com/banjworst]
- **LinkedIn**: [https://linkedin.com/in/sutherlandcs]
- **Email**: [sanjayarmani@gmail.com]

---

**Last Updated**: March 2026  
**Status**: Complete & Tested
