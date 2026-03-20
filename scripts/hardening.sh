#!/bin/bash

# Active Directory Security Hardening Script
# Core commands for securing a Samba4 AD domain controller

echo "Starting AD Security Hardening..."

# Create Security Groups
echo "Creating security groups..."
sudo samba-tool group add Domain_Admins_Restricted --description="Administrative users"
sudo samba-tool group add Service_Accounts --description="Service account group"
sudo samba-tool group add Privileged_Users --description="Users with elevated privileges"

# Create Test Users
echo "Creating test users..."
sudo samba-tool user create admin_user --given-name="Admin" --surname="User" --password=AdminUser123!
sudo samba-tool user create service_account --given-name="Service" --surname="Account" --password=ServiceAcct123!
sudo samba-tool user create regular_user --given-name="Regular" --surname="User" --password=RegularUser123!

# Add Users to Groups
echo "Adding users to groups..."
sudo samba-tool group addmembers Domain_Admins_Restricted admin_user
sudo samba-tool group addmembers Service_Accounts service_account
sudo samba-tool group addmembers Privileged_Users admin_user
sudo samba-tool group addmembers Privileged_Users service_account

# Verify Configuration
echo "Verifying configuration..."
echo ""
echo "Domain Users:"
sudo samba-tool user list

echo ""
echo "Security Groups:"
sudo samba-tool group listmembers Domain_Admins_Restricted

echo ""
echo "Password Policy:"
sudo samba-tool domain passwordsettings show

echo ""
echo "AD Security Hardening Complete"
