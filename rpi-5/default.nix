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

      # ignoreConfigErrors = true;

      # structuredExtraConfig = with lib.kernel; {
      #   MODULES = lib.mkForce yes;
      #   MODULE_UNLOAD = lib.mkForce yes;
        
      #   # mandatory for /boot
      #   NLS_CODEPAGE_437 = lib.mkForce yes;
      #   NLS_ISO8859_1   = lib.mkForce yes;
      #   FAT_FS          = lib.mkForce yes;
      #   VFAT_FS         = lib.mkForce yes;

      #   CRYPTO_ZSTD = lib.mkForce yes;
      #   CRYPTO_LZO  = lib.mkForce yes;
      #   CRYPTO_LZ4  = lib.mkForce yes;
      #   ZSTD_COMPRESS   = lib.mkForce yes;
      #   ZSTD_DECOMPRESS = lib.mkForce yes;
      #   LZO_COMPRESS    = lib.mkForce yes;
      #   LZO_DECOMPRESS  = lib.mkForce yes;
      #   DECOMPRESS_XZ = lib.mkForce yes;
      #   XZ_DEC        = lib.mkForce yes;


      #   ZRAM = lib.mkForce yes;
      #   ZSWAP = lib.mkForce yes;
        
      #   DRM_NOUVEAU = lib.mkForce no;
      #   DRM_AMDGPU = lib.mkForce no;
      #   DRM_RADEON = lib.mkForce no;
      #   DRM_I915 = lib.mkForce no; # GPU Intel
      #   DRM_VGEM = lib.mkForce no;

      #   HYPERV = lib.mkForce no;
      #   HYPERV_BALLOON = lib.mkForce no;
      #   HYPERV_NET = lib.mkForce no;
      #   HYPERV_KEYBOARD = lib.mkForce no;
      #   FB_HYPERV = lib.mkForce no;
      #   DRM_HYPERV = lib.mkForce no;
      #   HYPERV_STORAGE = lib.mkForce no;

      #   VMWARE_BALLOON = lib.mkForce no;
      #   VMWARE_VMCI = lib.mkForce no;
      #   VMWARE_PVSCSI = lib.mkForce no;
      #   DRM_VMWGFX = lib.mkForce no;
      #   DRM_VBOXVIDEO = lib.mkForce no;
      #   DRM_QXL = lib.mkForce no;

      #   XEN = lib.mkForce no;

      #   BTRFS_FS = lib.mkForce no;
      # };

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
