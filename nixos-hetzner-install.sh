#! /usr/bin/env bash

# Script to install NixOS from the Hetzner Cloud NixOS bootable ISO image.
# Wipes the disk!
# Tested with Hetzner's `NixOS 20.03 (amd64/minimal)` ISO image.
#
# Run like:
#
#     curl https://nh2.me/nixos-install-hetzner-cloud.sh | sudo bash
#
# To run it from the Hetzner Cloud web terminal without typing it down,
# use `xdotoool` (you have e.g. 3 seconds to focus the window):
#
#     sleep 3 && xdotool type --delay 50 'curl https://nh2.me/nixos-install-hetzner-cloud.sh | sudo bash'
#
# (In the xdotool invocation you may have to replace chars so that
# the right chars appear on the US-English keyboard.)
#
# If you want to be able to SSH straight in,
# do not forget to replace the SSH key below by yours
# (in the section labelled "Replace this by your SSH pubkey"),
# and host script modified this way under and URL of your choosing.
# Otherwise you'l be running with my pubkey, but you can change it
# afterwards by logging in via the Hetzner Cloud web terminal as `root`
# with empty password.

set -e

# Hetzner Cloud OS images grow the root partition to the size of the local
# disk on first book. In case the NixOS live ISO is booted immediately on
# first powerup, that does not happen. Thus we need to grow the partition
# by deleting and re-creating it.
sgdisk -d 1 /dev/sda
sgdisk -N 1 /dev/sda
partprobe /dev/sda

mkfs.ext4 -F /dev/sda1 # wipes all data!

mount /dev/sda1 /mnt

nixos-generate-config --root /mnt

# Delete trailing `}` from `configuration.nix` so that we can append more to it.
sed -i -E 's:^\}\s*$::g' /mnt/etc/nixos/configuration.nix

# Extend/override default `configuration.nix`:
echo '
  boot.loader.grub.devices = [ "/dev/sda" ];

  # Initial empty root password for easy login:
  users.users.root.initialHashedPassword = "";
  services.openssh.permitRootLogin = "prohibit-password";

  services.openssh.enable = true;

  # Replace this by your SSH pubkey
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCvmrk3i04tXfrSlZtHFbG3o6lQgh3ODMWmGDING4TJ4ctidexmMNY15IjVjzXZgQSET1uKLDLITiaPsii8vaWERZfjm3jjub845mpKkKv48nYdM0eCbv7n604CA3lwoB5ebRgULg4oGTi60rQ4trFf3iTkJfmiLsieFBZz7l+DfgeDEjDNSJcrkOggGBrjE5vBXoDimdkNh8kBNwgMDj1kPR/FHDqybSd5hohCJ5FzQg9vzl/x/H1rzJJKYPO4svSgHkYNkeoL84IZNeHom+UEHX0rw2qAIEN6AiHvNUJR38relvQYxbVdDSlaGN3g26H2ehsmolf+U0uQlRAXTHo0NbXNVYOfijFKL/jWxNfH0aRycf09Lu60oY54gkqS/J0GoQe/OGNq1Zy72DI+zAwEzyCGfSDbAgVF7Y3mU2HqcqGqNzu7Ade5oCbLmkT7yzDM3x6IsmT1tO8dYiT8Qv+zFAECkRpw3yDkJkPOxNKg10oM318whMTtM3yqntE90hk="
  ];
}
' >> /mnt/etc/nixos/configuration.nix

nixos-install --no-root-passwd

reboot
