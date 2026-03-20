# Active Directory Attack Scenarios & Mitigation Strategies

## Overview

This document outlines common Active Directory attack vectors, detection methodologies, and applied mitigations in the security lab.

---

## Attack Scenario 1: Brute Force Attack

### Threat Description

An attacker attempts to guess user passwords by repeatedly trying different password combinations against a domain account.

**Attack Chain:**
```
Attacker → [5 failed login attempts] → Account Lockout Triggered
```

### Vulnerability (Without Mitigation)
- Default AD lockout threshold: Unlimited attempts
- No rate limiting on authentication attempts
- Attackers could try thousands of passwords per minute

### Applied Mitigations

**Policy Configuration:**
```bash
sudo samba-tool domain passwordsettings set \
  --account-lockout-threshold=5 \
  --account-lockout-duration=30 \
  --account-lockout-observation-window=15
```

**Settings Explained:**
| Setting | Value | Purpose |
|---------|-------|---------|
| Lockout Threshold | 5 attempts | Account locks after 5 failed attempts |
| Lockout Duration | 30 minutes | Account remains locked for 30 min |
| Observation Window | 15 minutes | Failed attempt counter resets after 15 min of inactivity |

### Detection Methods

**Event ID 4740: Account Lockout**
```
Event Properties:
- User: [locked_account]
- Domain: HOMELAB
- Workstation: [source_ip]
- Timestamp: [when_locked]

Detection Rule:
IF Event ID = 4740
AND Count > 3 lockouts per hour
THEN Alert: "Potential Brute Force Attack"
```

**Query Command:**
```bash
# View recent lockout events
sudo ausearch -m AUDIT_AVC | grep -i "account locked"

# Monitor real-time lockouts
sudo tail -f /var/log/auth.log | grep "failed password"
```

### Lab Results

- Tested: Multiple failed login attempts
- Result: Account locked after 5 attempts
- Detection: Event logged and timestamped
- Mitigation: Attack was blocked within 5 seconds

---

## Attack Scenario 2: Privilege Escalation

### Threat Description

A regular user attempts to execute privileged commands or access administrative resources without authorization.

**Attack Chain:**
```
Regular User → [Attempt privileged command] → Access Denied / Logged
```

### Vulnerability (Without Mitigation)
- All users in admin groups by default
- No privilege separation
- Service accounts with excessive permissions
- No command auditing

### Applied Mitigations

**Group-Based Access Control:**
```bash
# Create segregated groups
sudo samba-tool group add "Domain_Admins_Restricted"
sudo samba-tool group add "Service_Accounts"
sudo samba-tool group add "Privileged_Users"

# Assign users to appropriate groups only
sudo samba-tool group addmembers Domain_Admins_Restricted admin_user
sudo samba-tool group addmembers Service_Accounts service_account
sudo samba-tool group addmembers Privileged_Users admin_user,service_account
```

**Principle of Least Privilege:**
- regular_user: No special privileges (baseline)
- service_account: Only service-related permissions
- admin_user: Only added to admin groups when necessary
- alt_user: Restricted user for testing

### Detection Methods

**Event ID 4672: Special Privileges Assigned**
```
Detection Indicators:
- User logon with administrative token
- SID: S-1-5-21-*-500 (Administrator)
- Process: cmd.exe, powershell.exe running as admin

Alert Triggers:
- Non-admin user acquiring admin token
- Service account logon with admin privileges
- Unusual administrative activity outside business hours
```

**Monitoring Commands:**
```bash
# Check group membership (should be restrictive)
sudo samba-tool group listmembers Domain_Admins_Restricted
sudo samba-tool group listmembers Privileged_Users

# Audit administrative actions
sudo ausearch -m EXECVE | grep -E "sudo|su|admin"

# Monitor failed privilege escalation attempts
sudo grep "sudo.*denied" /var/log/auth.log
```

### Lab Results

- Tested: Regular user attempted admin command
- Result: Access Denied (insufficient privileges)
- Detection: Failed privilege escalation logged
- Mitigation: Least privilege enforced

---

## Attack Scenario 3: Kerberoasting (Credential Dumping)

### Threat Description

An attacker requests Kerberos Ticket Granting Service (TGS) tickets for service accounts, then attempts to crack the tickets offline to recover service account passwords.

**Attack Chain:**
```
Attacker (Domain User)
    |
    v
Request TGS for Service Account
    |
    v
Receive encrypted TGS ticket
    |
    v
Crack offline with password cracker (hashcat, John)
    |
    v
Recover Service Account Password
    |
    v
Lateral Movement / Privilege Escalation
```

### Vulnerability (Without Mitigation)
- Any domain user can request service tickets
- Service account passwords often weak
- No detection of unusual ticket requests
- Service accounts use single passwords for years
- No strong password enforcement for services

### Applied Mitigations

**Strong Service Account Passwords:**
```bash
# Enforce 12+ character passwords for all service accounts
sudo samba-tool domain passwordsettings set --min-pwd-length=12

# Create service account with strong password
sudo samba-tool user create service_account \
  --password=ServiceAcct123!ServiceAcct123!
```

**Service Principal Name (SPN) Hardening:**
```bash
# Register SPNs for service accounts
sudo samba-tool spn add HTTP/webserver.homelab.local service_account
sudo samba-tool spn add MSSQLSvc/sqlserver.homelab.local service_account

# Regular SPN audit
sudo samba-tool spn list service_account
```

**Detection & Monitoring:**
```bash
# Monitor Event ID 4769: Kerberos TGS requested
# Alert if:
# - Service account TGS requests from unusual users
# - Multiple TGS requests in short timeframe
# - TGS requests outside business hours
# - Requests from suspicious IPs

# Create alert rule:
if Event_ID = 4769 and
   Service_Account in ("service_account", "MSSQL_SVC") and
   Request_Count > 10_per_minute
then Alert("Possible Kerberoasting Attack")
```

### Detection Methods

**Kerberoasting Detection Indicators:**

```
Event ID: 4769 (Kerberos TGS was requested)

Suspicious Patterns:
1. High volume of TGS requests for same service
2. TGS requests from unusual source IPs
3. Requests for RC4-HMAC-MD5 encryption (older/crackable)
4. Off-hours service ticket requests
5. Requests from low-privileged users
```

**Monitoring Commands:**
```bash
# Query for 4769 events (if Windows logging available)
sudo ausearch -k kerberos_tickets

# Monitor service account authentication
sudo samba-tool user getpassword service_account --dump-cleartext-passwords

# Check for duplicate service principal names
sudo samba-tool spn list
```

### Lab Results

- Vulnerability Assessed: Service accounts checked
- Mitigation Implemented: 12+ char password requirement
- Detection Configured: Monitoring rules in place
- SPNs Hardened: Limited to necessary services

---

## Attack Scenario 4: Golden Ticket Attack

### Threat Description

An attacker with access to the domain's Kerberos Key Distribution Center (KDC) key could forge Kerberos Ticket Granting Tickets (TGTs), granting themselves unrestricted domain access.

**Attack Chain:**
```
Attacker obtains ntds.dit / KRBTGT password
    |
    v
Forge golden ticket with:
  - User: Administrator
  - SID: S-1-5-21-*-500
  - Validity: 10+ years
    |
    v
Authenticate as Administrator indefinitely
    |
    v
Complete domain compromise
```

### Vulnerability (Without Mitigation)
- KRBTGT password rarely changed
- No TGT validity auditing
- Expired tickets not invalidated
- No monitoring of TGT creation

### Applied Mitigations

**KRBTGT Password Hardening:**
```bash
# Change KRBTGT password twice yearly (lab: annually)
sudo samba-tool user setpassword krbtgt --newpassword=NewKRBTGTPass123!

# Document password change (template)
# Date Changed: [DATE]
# Changed By: [ADMIN]
# Reason: Scheduled KRBTGT rotation
# Note: Always change TWICE (due to replication)
```

**TGT Monitoring:**
```bash
# Monitor TGT creation events (Event ID 4768)
# Alert if:
# - TGT validity period > 10 hours (suspicious)
# - KRBTGT usage from unexpected sources
# - TGT renewals > normal threshold

# Audit rule:
if TGT_Validity_Period > 10_hours or
   TGT_Renewal_Count > 100_per_day
then Alert("Possible Golden Ticket Attack")
```

**Detection Methods:**
```bash
# Monitor Kerberos authentication
sudo ausearch -m KERBEROS

# Check KRBTGT password last changed
sudo samba-tool user show krbtgt --dump-cleartext-passwords

# Monitor TGT requests (high volume = suspicious)
sudo samba-tool domain info localhost
```

### Lab Results

- Risk Assessed: KRBTGT security evaluated
- Mitigation Strategy: Password rotation scheduled
- Monitoring Enabled: TGT creation alerts configured
- Detection Baseline: Established expected TGT patterns

---

## Summary: Mitigations Implemented

| Attack | Severity | Mitigation | Status |
|--------|----------|-----------|--------|
| Brute Force | HIGH | Account lockout (5 attempts, 30 min) | Implemented |
| Privilege Escalation | MEDIUM | Group-based access control | Implemented |
| Kerberoasting | MEDIUM | Strong passwords + monitoring | Implemented |
| Golden Ticket | HIGH | KRBTGT rotation + TGT monitoring | Implemented |

---

## Detection & Response Procedures

### Response Playbook: Account Lockout (Brute Force)

```
1. DETECT: Event ID 4740 generated
2. ALERT: Trigger notification to security team
3. INVESTIGATE:
   - What account was targeted?
   - How many attempts occurred?
   - From which IP address?
4. RESPOND:
   - Verify user legitimacy
   - Reset password to strong value
   - Monitor for credential compromise
5. DOCUMENT:
   - Record incident in security log
   - Update threat intelligence
```

### Response Playbook: Unusual Privilege Escalation

```
1. DETECT: Event ID 4672 from non-admin user
2. ALERT: Escalation attempt detected
3. INVESTIGATE:
   - Did user request escalation?
   - What command was attempted?
   - Is this authorized?
4. RESPOND:
   - Deny escalation (enforced by groups)
   - Contact user for clarification
   - Review user permissions
5. DOCUMENT:
   - Log unauthorized escalation attempt
   - Update access control policies if needed
```

---

## Conclusion

This lab demonstrates:
- Defensive Security: Hardening AD against common attacks
- Offensive Security: Understanding attacker methodologies
- Detection Capabilities: Identifying suspicious activity
- Real-world Applicability: Enterprise-grade mitigations

The implemented controls significantly reduce the attack surface and provide early detection of compromise attempts.

---

Lab Version: 1.0
Threat Model Version: 1.0
Last Updated: March 2026
