# Setup Guide: Active Directory Security Hardening Lab

## Prerequisites

- Hardware: M1/M2/M3/M4 Mac or Linux system with 8GB+ RAM
- Software: UTM or VMware/Parallels Desktop
- OS: Ubuntu Server 20.04 LTS or newer
- Disk Space: 100GB minimum for VMs

---

## Step 1: Create Linux VM (If Not Already Done)

### In UTM:
1. Click + → Virtualize
2. Select Linux
3. Download Ubuntu Server 20.04 LTS ARM64
4. Allocate: 4GB RAM, 60GB disk
5. Boot and install

### After Ubuntu Installation:
```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install required packages
sudo apt install -y \
  samba \
  samba-dsdb-modules \
  samba-vfs-modules \
  krb5-config \
  krb5-user \
  winbind \
  libnss-winbind \
  libpam-winbind \
  libpam-krb5 \
  python3-samba \
  samba-tool \
  auditd \
  curl \
  git

# Enable auditd
sudo systemctl enable auditd
sudo systemctl start auditd
```

---

## Step 2: Provision Samba4 Active Directory

```bash
# Remove existing Samba installation
sudo systemctl stop samba
sudo systemctl disable samba
sudo apt remove -y samba samba-common

# Backup existing configs (if any)
sudo mv /etc/samba /etc/samba.bak 2>/dev/null

# Provision new AD forest
sudo samba-tool domain provision \
  --use-rfc2307 \
  --realm=HOMELAB.LOCAL \
  --domain=HOMELAB \
  --adminpass=AdminPassword123! \
  --server-role=dc \
  --dns-backend=INTERNAL

# Symlink Kerberos config
sudo ln -sf /var/lib/samba/private/krb5.conf /etc/krb5.conf

# Start Samba services
sudo systemctl unmask samba-ad-dc
sudo systemctl enable samba-ad-dc
sudo systemctl start samba-ad-dc

# Verify
sudo samba-tool domain info localhost
```

Note the Admin Password: Store this securely. You'll need it for domain operations.

---

## Step 3: Configure Security Hardening

### 3A: Set Strong Password Policy

```bash
# Apply password security standards
sudo samba-tool domain passwordsettings set \
  --min-pwd-length=12 \
  --pwd-history-length=5 \
  --account-lockout-threshold=5 \
  --account-lockout-duration=30 \
  --account-lockout-observation-window=15

# Verify policy
sudo samba-tool domain passwordsettings show
```

Explanation:
- --min-pwd-length=12: Minimum 12 characters (vs default 7)
- --pwd-history-length=5: Last 5 passwords cannot be reused
- --account-lockout-threshold=5: Lock after 5 failed attempts
- --account-lockout-duration=30: 30-minute lockout period
- --account-lockout-observation-window=15: Reset counter after 15 min of no failures

### 3B: Create Security Groups

```bash
# Create privileged access groups
sudo samba-tool group add "Domain_Admins_Restricted" \
  --description="Administrative users with full domain access"

sudo samba-tool group add "Service_Accounts" \
  --description="Service account group for application services"

sudo samba-tool group add "Privileged_Users" \
  --description="Users with elevated but not full admin privileges"

sudo samba-tool group add "Audit_Users" \
  --description="Users allowed to view audit logs"

# Verify groups
sudo samba-tool group list
```

### 3C: Create Test Users with Different Privilege Levels

```bash
# Admin user (high privilege)
sudo samba-tool user create admin_user \
  --given-name="Admin" \
  --surname="User" \
  --password=AdminUser123! \
  --mail-address=admin_user@homelab.local

# Service account
sudo samba-tool user create service_account \
  --given-name="Service" \
  --surname="Account" \
  --password=ServiceAcct123! \
  --mail-address=service_account@homelab.local

# Regular user
sudo samba-tool user create regular_user \
  --given-name="Regular" \
  --surname="User" \
  --password=RegularUser123! \
  --mail-address=regular_user@homelab.local

# Alternative user (for lateral movement testing)
sudo samba-tool user create alt_user \
  --given-name="Alternate" \
  --surname="User" \
  --password=AltUser123! \
  --mail-address=alt_user@homelab.local

# Verify users
sudo samba-tool user list
```

### 3D: Assign Users to Groups

```bash
# Add admin user to admin groups
sudo samba-tool group addmembers Domain_Admins_Restricted admin_user
sudo samba-tool group addmembers Privileged_Users admin_user

# Add service account to service group
sudo samba-tool group addmembers Service_Accounts service_account
sudo samba-tool group addmembers Privileged_Users service_account

# Add regular user to audit group
sudo samba-tool group addmembers Audit_Users regular_user

# Verify memberships
sudo samba-tool group listmembers Domain_Admins_Restricted
sudo samba-tool group listmembers Service_Accounts
```

---

## Step 4: Enable Audit Logging

### 4A: Configure auditd Rules

```bash
# Create audit rules file for Samba
sudo tee /etc/audit/rules.d/samba.rules > /dev/null <<EOF
# Monitor Samba database changes
-w /var/lib/samba/private/sam.ldb -p wa -k samba_sam_changes
-w /var/lib/samba/private/ -p wa -k samba_private_changes

# Monitor AD-related system calls
-a always,exit -F arch=b64 -S adjtimex,settimeofday -k time_change
-a always,exit -F arch=b64 -S sethostname,setdomainname -k network_config

# Monitor user/group modifications
-a always,exit -F arch=b64 -S adduserdata -k user_modifications
EOF

# Load rules
sudo service auditd restart

# Verify rules are loaded
sudo auditctl -l | grep samba
```

### 4B: View Audit Events

```bash
# Search for Samba-related audit events
sudo ausearch -k samba_sam_changes

# Search for account modifications
sudo ausearch -m ADD_USER,DEL_USER,ADD_GROUP,DEL_GROUP

# Real-time audit monitoring
sudo tail -f /var/log/audit/audit.log | grep samba
```

---

## Step 5: Configure DNS (Critical for AD)

### 5A: Verify DNS is Running

```bash
# Check if Samba DNS is running
sudo systemctl status samba-ad-dc

# Test DNS resolution
sudo nslookup homelab.local 127.0.0.1
sudo nslookup dc.homelab.local 127.0.0.1

# Check DNS records
sudo samba-tool dns zonelist localhost
```

### 5B: Add DNS Records (If Needed)

```bash
# Add A record for domain controller
sudo samba-tool dns add localhost homelab.local @ A 192.168.64.4 \
  --username=Administrator --password=AdminPassword123!

# Add SRV records for Kerberos
sudo samba-tool dns add localhost homelab.local _kerberos._udp SRV 0 100 88 dc.homelab.local \
  --username=Administrator --password=AdminPassword123!
```

---

## Step 6: Security Configuration Verification

```bash
# Run comprehensive check
echo "=== Security Configuration Verification ==="

echo -e "\n[1] Password Policy:"
sudo samba-tool domain passwordsettings show

echo -e "\n[2] Group Membership:"
sudo samba-tool group listmembers Domain_Admins_Restricted
sudo samba-tool group listmembers Service_Accounts

echo -e "\n[3] User Status:"
sudo samba-tool user list

echo -e "\n[4] DNS Functionality:"
sudo nslookup homelab.local 127.0.0.1

echo -e "\n[5] Audit Logging:"
sudo auditctl -l | head -20

echo -e "\n[6] Samba Services:"
sudo systemctl status samba-ad-dc --no-pager
sudo systemctl status samba --no-pager
```

---

## Step 7: Run Security Lab Script

```bash
# Download or create the attack simulation script
python3 scripts/ad_security_lab.py

# Expected output shows:
# - Password policy validated
# - Attack simulations documented
# - Detection methods outlined
# - Mitigation strategies confirmed
```

---

## Troubleshooting

### Issue: "samba-tool: command not found"
```bash
sudo apt install -y python3-samba samba-tool
```

### Issue: DNS not resolving
```bash
# Check Samba DNS service
sudo systemctl status samba-ad-dc
sudo samba-tool dns zonelist localhost

# Manually start if stopped
sudo systemctl start samba-ad-dc
```

### Issue: Cannot connect to domain
```bash
# Verify domain info
sudo samba-tool domain info localhost

# Check Kerberos configuration
cat /etc/krb5.conf

# Test Kerberos
kinit Administrator@HOMELAB.LOCAL
```

### Issue: Audit logging not working
```bash
# Restart auditd
sudo systemctl restart auditd

# Check status
sudo systemctl status auditd

# Verify rules
sudo auditctl -l
```

---

## Next Steps

1. Document all passwords securely
2. Take screenshots of configuration
3. Run attack simulation script
4. Test with Windows client (optional)
5. Push to GitHub with documentation
6. Share on LinkedIn

---

## Security Notes

WARNING: This is a lab environment. Do NOT use weak passwords or these configurations in production.

Production Recommendations:
- Use Hardware Security Module (HSM) for key storage
- Implement multi-factor authentication (MFA)
- Use Azure AD or on-premises AD with Windows Server
- Deploy SIEM for centralized logging
- Regular security audits and penetration testing

---

Lab Version: 1.0
Last Updated: March 2026
