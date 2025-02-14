#!/usr/bin/env bash
# ----------------------------------------------------------------------------------
# Filename:     pvesource_ct_ubuntubasics.sh
# Description:  Source script for setting up Ubuntu CT basic configuration
# ----------------------------------------------------------------------------------

#---- Source -----------------------------------------------------------------------
#---- Dependencies -----------------------------------------------------------------

function pct_start_waitloop () {
  if [ "$(pct status $CTID)" == "status: stopped" ]; then
    msg "Starting CT $CTID..."
    pct start $CTID
    msg "Waiting to hear from CT $CTID..."
    while ! [[ "$(pct status $CTID)" == "status: running" ]]; do
      echo -n .
    done
    sleep 2
    info "CT $CTID status: ${GREEN}running${NC}"
    echo
  fi
}

#---- Static Variables -------------------------------------------------------------
#---- Other Variables --------------------------------------------------------------
#---- Other Files ------------------------------------------------------------------
#---- Body -------------------------------------------------------------------------

section "Configure ${OSTYPE^} CT system defaults"

# Start container
pct_start_waitloop

# Set Container locale
msg "Setting ${OSTYPE^} CT locale to match PVE host locale..."
PVE_HOST_LOCALE=$(locale | grep -w '^LANG=.*' | sed 's/LANG=//')
export PVE_HOST_LOCALE
pct exec $CTID -- locale-gen $PVE_HOST_LOCALE > /dev/null
pct exec $CTID -- update-locale LC_ALL=$PVE_HOST_LOCALE > /dev/null
pct exec $CTID -- locale-gen --purge $PVE_HOST_LOCALE > /dev/null
pct exec $CTID -- dpkg-reconfigure --frontend noninteractive locales 2> /dev/null

# Update container OS
msg "Updating ${OSTYPE^} CT OS (be patient, might take a while)..."
pct exec $CTID -- apt-get -qqy update > /dev/null
pct exec $CTID -- apt-get -qqy upgrade > /dev/null
pct exec $CTID -- apt-get -qqy autoremove > /dev/null

# Configuring Ubuntu for unattended upgrades
msg "Setting ${OSTYPE^} CT for unattended upgrades..."
pct exec $CTID -- apt-get install -qqy unattended-upgrades > /dev/null
# Enable Updates
pct exec $CTID -- sed -i 's|//\t"${distro_id}:${distro_codename}-updates";|\t"${distro_id}:${distro_codename}-updates";|' /etc/apt/apt.conf.d/50unattended-upgrades
# Enable Removal of unused files
pct exec $CTID -- sed -i 's|//Unattended-Upgrade::Remove-Unused-Kernel-Packages "true";|Unattended-Upgrade::Remove-Unused-Kernel-Packages "true";|' /etc/apt/apt.conf.d/50unattended-upgrades
pct exec $CTID -- sed -i 's|//Unattended-Upgrade::Remove-New-Unused-Dependencies "true";|Unattended-Upgrade::Remove-New-Unused-Dependencies "true";|' /etc/apt/apt.conf.d/50unattended-upgrades
# Auto reboot CT if required
pct exec $CTID -- sed -i 's|//Unattended-Upgrade::Automatic-Reboot "false";|Unattended-Upgrade::Automatic-Reboot "true";|' /etc/apt/apt.conf.d/50unattended-upgrades
pct exec $CTID -- sed -i 's|//Unattended-Upgrade::Automatic-Reboot-Time "02:00";|Unattended-Upgrade::Automatic-Reboot-Time "03:00";|' /etc/apt/apt.conf.d/50unattended-upgrades
# Start Unattended Upgrade
pct exec $CTID -- unattended-upgrade > /dev/null

# Installing HTTPS transport
msg "Installing HTTPS transport for APT..."
pct exec $CTID -- apt-get -qqy install apt-transport-https > /dev/null

# Installing GnuPG
msg "Installing GnuPG and CA Certificates..."
pct exec $CTID -- apt-get -qqy install gnupg2 ca-certificates > /dev/null

# GPG creating defaults
msg "Creating GnuPG default directory, keybox and trustdb..."
pct exec $CTID -- gpg -k &> /dev/null

# Installing curl
msg "Installing curl..."
pct exec $CTID -- apt-get -qqy install curl > /dev/null
echo

# msg "Installing ACL..."
# msg "Installing ACL ( (Access Control Lists)..."
# pct exec $CTID -- sudo apt-get install -y acl > /dev/null

#---- Finish Line ------------------------------------------------------------------