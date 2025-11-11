#!/bin/sh
set -e

build_module() {
    local mod=$1 base=$2 kernel=$3

  if [ -d /var/lib/dkms/$mod ]; then
    # Clean up stale versions
    for stale_version in $(ls /var/lib/dkms/$mod | grep -v source); do
      [ "$stale_version" != "$base" ] && dkms remove $mod/$stale_version --all 2>/dev/null && rm -rf /var/lib/dkms/$mod/$stale_version
    done

    # Get the module version (fallback to hardcoded)
    dkms_version=$(dkms status | grep $mod | head -1 | cut -d, -f1 | cut -d/ -f2 | tr -d ' ')
    [ -n "$dkms_version" ] && module_version="$dkms_version" || module_version="$base"

    # Register the module
    dkms add $mod/$module_version 2>/dev/null || true

    # Confirm the source exists
    if [ ! -d "/usr/src/$mod-$module_version" ]; then
      echo "'/usr/src/$mod-$module_version' not found. Try reinstalling ${mod}-dkms." | tee -a /var/log/dkms.log | logger -t zz-dkms-rebuild
      exit 2
    fi

    # Build the module
    if dkms build $mod/$module_version -k "$kernel" 2>&1 | tee /tmp/dkms-$mod-$kernel.log; then
      # Remove old module only if build succeeds
      dkms remove $mod/$module_version -k "$kernel" 2>/dev/null || true
      # Install the module
      dkms install --force $mod/$module_version -k "$kernel"
      # Decompress .ko.zst files
      find /var/lib/dkms/$mod/$module_version -name "*.ko.zst" -exec unzstd --rm {} \; 2>>/var/log/dkms.log || {
        echo "Failed to decompress .ko.zst files in /var/lib/dkms/$mod/$module_version" | tee -a /var/log/dkms.log | logger -t zz-dkms-rebuild
      }
      find /usr/lib/modules/"$kernel"/updates/dkms -name "*.ko.zst" -exec unzstd --rm {} \; 2>>/var/log/dkms.log || {
        echo "Failed to decompress .ko.zst files in /usr/lib/modules/$kernel/updates/dkms" | tee -a /var/log/dkms.log | logger -t zz-dkms-rebuild
      }
      # Ensure module directory exists
      mkdir -p /usr/lib/modules/"$kernel"/updates/dkms
      # Copy .ko files using symlink path
      if [ -d "/var/lib/dkms/$mod/kernel-$kernel-x86_64/module" ]; then
        cp /var/lib/dkms/$mod/kernel-$kernel-x86_64/module/*.ko /usr/lib/modules/"$kernel"/updates/dkms/ 2>/dev/null || {
          echo "Failed to copy .ko files for $mod to /usr/lib/modules/$kernel/updates/dkms" | tee -a /var/log/dkms.log | logger -t zz-dkms-rebuild
        }
      else
        echo "Warning: Symlink '/var/lib/dkms/$mod/kernel-$kernel-x86_64/module' not found. .ko files not copied." | tee -a /var/log/dkms.log | logger -t zz-dkms-rebuild
      fi
      rm -f /usr/lib/modules/"$kernel"/updates/dkms/*.ko.zst 2>/dev/null || true
      # Update dependencies and initramfs
      depmod -a "$kernel"
      update-initramfs -u -k "$kernel"
    else
      echo "DKMS build failed for $mod/$module_version on $kernel. Check /tmp/dkms-$mod-$kernel.log" | tee -a /var/log/dkms.log | logger -t zz-dkms-rebuild
      exit 1
    fi
  fi
}

# If this runs only as a post install step then this can just be a local variable in the function
# But maybe it makes more sense to have it be able to be specified so that it can be run as needed?
the_kernel=$(uname -r)

build_module "nvidia" "580.95.05" $the_kernel
build_module "virtualbox" "7.0.16" $the_kernel