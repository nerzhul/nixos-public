{
  config,
  pkgs,
  lib,
  ...
}:

let
  modDirVersion = "6.18.39";
  tag = "stable_20260724";

  linux_rpi5 =
    (pkgs.buildLinux {
      version = "${modDirVersion}-${tag}";
      inherit modDirVersion;

      src = pkgs.fetchFromGitHub {
        owner = "raspberrypi";
        repo = "linux";
        rev = tag;
        hash = "sha256-IT/SkF458oLmnFIPbN76Qp6s8KVxKQOC02XmN7NRdBc=";
      };

      defconfig = "bcm2712_defconfig";

      kernelPatches = [
        pkgs.kernelPatches.bridge_stp_helper
        pkgs.kernelPatches.request_key_helper
      ];

      features = {
        efiBootStub = false;
        #iwlwifi = false;
      };

      ignoreConfigErrors = true;

      extraMeta = {
        platforms = [ "aarch64-linux" ];
        hydraPlatforms = [ "aarch64-linux" ];
      };
    }).overrideAttrs
      (oldAttrs: {
        postConfigure = ''
          sed -i $buildRoot/.config -e 's/^CONFIG_LOCALVERSION=.*/CONFIG_LOCALVERSION=""/'
          sed -i $buildRoot/.config -e 's/^CONFIG_LOCALVERSION_AUTO=.*/CONFIG_LOCALVERSION_AUTO=n/'
          sed -i $buildRoot/include/config/auto.conf -e 's/^CONFIG_LOCALVERSION=.*/CONFIG_LOCALVERSION=""/'

          # Force-disable (any value -> '# CONFIG_X is not set')
          sed -i $buildRoot/.config -E \
            -e 's/^CONFIG_(DRM_NOUVEAU|DRM_AMDGPU|DRM_RADEON|DRM_I915|DRM_VGEM|HYPERV|HYPERV_BALLOON|HYPERV_NET|HYPERV_KEYBOARD|FB_HYPERV|DRM_HYPERV|HYPERV_STORAGE|VMWARE_BALLOON|VMWARE_VMCI|VMWARE_PVSCSI|DRM_VMWGFX|DRM_VBOXVIDEO|DRM_QXL|XEN|BTRFS_FS)=.*/# CONFIG_\1 is not set/'
        '';

        postFixup = ''
          dtbDir=$out/dtbs/broadcom
          rm -f $dtbDir/bcm283*.dtb
          copyDTB() {
            if [ -f "$dtbDir/$1" ]; then
              cp -v "$dtbDir/$1" "$dtbDir/$2"
            fi
          }
          copyDTB bcm2710-rpi-zero-2.dtb bcm2837-rpi-zero-2.dtb
          copyDTB bcm2710-rpi-3-b.dtb bcm2837-rpi-3-b.dtb
          copyDTB bcm2710-rpi-3-b-plus.dtb bcm2837-rpi-3-a-plus.dtb
          copyDTB bcm2710-rpi-3-b-plus.dtb bcm2837-rpi-3-b-plus.dtb
          copyDTB bcm2710-rpi-cm3.dtb bcm2837-rpi-cm3.dtb
          copyDTB bcm2711-rpi-4-b.dtb bcm2838-rpi-4-b.dtb
        '';
      });

in
{
  boot.kernelPackages = pkgs.linuxPackagesFor linux_rpi5;
}
