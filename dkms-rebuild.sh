#!/usr/bin/env bash

# This script was built from a conversation with Grok (https://grok.com/c/3d149a35-ac28-4ba2-aa5c-855ab9bf2dde)
# on the issue around DKMS files not being included as part of the kernel build.  I experienced this with
# 6.8.0-50 and later with 6.11.0-28.  The conversation makes clear this is not unique to my systems and is a knonw
# issue with how Ubuntu was building the kernel.  This script addresses that by taking the steps needed to ensure
# that the DKMS modules are built and included in the initramfs.
#
# The question now, is whether to make it an automatic script in /etc/kernel/postinst.d (e.g., zz-dkms-rebuild),
# leave it as a manual step that can be run when it is determined to be necessary, or some combination; i.e.,
# have it check for the existence of the .ko files and if not found, proceed to build them.
#
# As this is currently written, it is pegged to specific versions of the DKMS and eliminates all other versions.
# Going forward that would have to be changed as these are built if a new version comes along and is to replace
# this pegged "base" version.

source /usr/local/lib/display.sh

set -e

show_syntax() {
  echo "Syntax: $(basename "$0") [-k|--kernel name] [-h|--help]"
  echo "Where:  [-k|--kernel name] is full name the kernel to build; defaults to the active kernel."
  echo "Sample: sudo dkms-rebuild -k 6.8.0-87-generic"
  exit
}

clean_module() {
  local mod=$1 kernel=$2
  local base=$(readlink "/var/lib/dkms/$mod/kernel-$kernel-x86_64" | cut -d'/' -f1)

  # show "mod=$mod, kernel=$kernel, base=$base"
  # read

  # Clean up stale versions
  for stale_version in $(ls /var/lib/dkms/"$mod" | grep -v source); do
    if [ "$stale_version" != "$base" ] && [ dkms remove "$mod/$stale_version" --all 2>/dev/null ]; then
        rm -rf /var/lib/dkms/"$mod/$stale_version"
    fi
  done
}

build_module() {
  local mod=$1 kernel=$2
  local base=$(readlink "/var/lib/dkms/$mod/kernel-$kernel-x86_64" | cut -d'/' -f1)

  # show "mod=$mod, kernel=$kernel, base=$base"
  # read

  local logfile="/tmp/dkms-$mod-$kernel.log"

  # Get the module version (fallback to hardcoded)
  dkms_version=$(dkms status | grep "$mod" | head -1 | cut -d, -f1 | cut -d/ -f2 | tr -d ' ')
  [ -n "$dkms_version" ] && module_version="$dkms_version" || module_version="$base"

  # Register the module
  dkms add "$mod/$module_version" 2>/dev/null || true

  # Confirm the source exists
  if [ ! -d "/usr/src/$mod-$module_version" ]; then
    show "'/usr/src/$mod-$module_version' not found. Try reinstalling ${mod}-dkms." | tee -a "$logfile"
    exit 2
  fi

  # Build the module
  if dkms build "$mod/$module_version" -k "$kernel" 2>&1 | tee "$logfile"; then
    # Remove old module only if build succeeds
    dkms remove "$mod/$module_version" -k "$kernel" 2>/dev/null || true
    # Install the module
    dkms install --force "$mod/$module_version" -k "$kernel"
    # Decompress .ko.zst files
    find /var/lib/dkms/"$mod/$module_version" -name "*.ko.zst" -exec unzstd --rm {} \; 2>>"$logfile" || {
      show "Failed to decompress .ko.zst files in /var/lib/dkms/$mod/$module_version" | tee -a "$logfile"
    }
    find /usr/lib/modules/"$kernel"/updates/dkms -name "*.ko.zst" -exec unzstd --rm {} \; 2>>"$logfile" || {
      show "Failed to decompress .ko.zst files in /usr/lib/modules/$kernel/updates/dkms" | tee -a "$logfile"
    }
    # Ensure module directory exists
    mkdir -p /usr/lib/modules/"$kernel"/updates/dkms
    # Copy .ko files using symlink path
    if [ -d "/var/lib/dkms/$mod/kernel-$kernel-x86_64/module" ]; then
      cp /var/lib/dkms/"$mod"/kernel-"$kernel"-x86_64/module/*.ko /usr/lib/modules/"$kernel"/updates/dkms/ 2>/dev/null || {
        show "Failed to copy .ko files for $mod to /usr/lib/modules/$kernel/updates/dkms" | tee -a "$logfile"
      }
    else
      show "Warning: Symlink '/var/lib/dkms/$mod/kernel-$kernel-x86_64/module' not found. .ko files not copied." | tee -a "$logfile"
    fi
    rm -f /usr/lib/modules/"$kernel"/updates/dkms/*.ko.zst 2>/dev/null || true
  else
    show "DKMS build failed for $mod/$module_version on $kernel. Check $logfile" | tee -a "$logfile"
    exit 3
  fi
}

if [ $# -lt 1 ]; then
  show_syntax
fi

name=$1
kernel=$2

if [ -z $kernel ]; then
  kernel=$(uname -r)
fi

# echo "kernel=$kernel"

if [[ "$EUID" != 0 ]]; then
  printx "This must be run as sudo.\n"
  exit
fi

for dir in /var/lib/dkms/*; do
  module=$(basename $dir)
  printx "Building module '$module'..."
  clean_module "$module" "$kernel"
  build_module "$module" "$kernel"
done

# Update dependencies and initramfs
depmod -a "$kernel"
update-initramfs -u -k "$kernel"

