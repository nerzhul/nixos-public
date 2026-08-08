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
            -e 's/^CONFIG_(DRM_NOUVEAU|DRM_AMDGPU|DRM_RADEON|DRM_I915|DRM_VGEM|DRM_VKMS|DRM_BOCHS|DRM_CIRRUS_QEMU|HYPERV|HYPERV_BALLOON|HYPERV_NET|HYPERV_KEYBOARD|FB_HYPERV|DRM_HYPERV|HYPERV_STORAGE|VMWARE_BALLOON|VMWARE_VMCI|VMWARE_PVSCSI|DRM_VMWGFX|DRM_VBOXVIDEO|DRM_QXL|XEN|BTRFS_FS|DEBUG_KERNEL|INPUT_JOYSTICK|INPUT_JOYDEV|INPUT_TABLET|INPUT_TOUCHSCREEN|NFC|MEDIA_TUNER|MEDIA_SUBDRV_AUTOMOUNT|SCSI_CONSTANTS|SCSI_LOGGING|SCSI_PROC_FS|SCSI_SPI_ATTRS|SCSI_FC_ATTRS|SCSI_SAS_ATTRS|SCSI_SAS_LIBSAS|SCSI_SRP_ATTRS|SCSI_MVSAS|SCSI_MVUMI|SCSI_ARCMSR|SCSI_AIC7XXX|SCSI_AIC79XX|SCSI_AACRAID|SCSI_MPT2SAS|SCSI_MPT3SAS|SCSI_SMARTPQI|SCSI_PMCRAID|SCSI_IPS|SCSI_INITIO|SCSI_INIA100|SCSI_STEX|SCSI_SYM53C8XX_2|SCSI_QLOGIC_1280|SCSI_QLOGIC_FC|SCSI_QLOGIC_IPS|SCSI_QLOGIC_QLA_ISCSI|SCSI_LPFC|SCSI_BFA_FC|SCSI_CHELSIO_FCOE|SCSI_DC395x|SCSI_AM53C974|SCSI_WD719X|SCSI_DEBUG|SCSI_OSD_INITIATOR|SCSI_OSD_ULD|SCSI_DH|SCSI_DH_RDAC|SCSI_DH_HP_SW|SCSI_DH_EMC|SCSI_DH_ALUA|SCSI_VIRTIO|JFS_FS|REISERFS_FS|XFS_FS|F2FS_FS|OCFS2_FS|GFS2_FS|UFS_FS|QNX4FS_FS|QNX6FS_FS|SYSV_FS|AFFS_FS|AFS_FS|9P_FS|NFS_FS|NFSD|CIFS|SMB_SERVER|ISO9660_FS|UDF_FS|HFS_FS|HFSPLUS_FS|NTFS_RW|NCP_FS|NCPFS_FS|BLK_DEV_RAM|BLK_DEV_NBD|BLK_DEV_RBD|BLK_DEV_MD|MD_LINEAR|MD_RAID0|MD_RAID1|MD_RAID10|MD_RAID456|MD_MULTIPATH|BLK_DEV_DRBD|BLK_DEV_PMEM|CDROM|BLK_DEV_SR|BLK_DEV_SCD|BLK_DEV_UBLK|ATA|SATA_AHCI_PLATFORM|ATA_PIIX|ATA_GENERIC|SATA_AHCI|PATA_ACPI|PATA_ALI|PATA_AMD|PATA_ARTOP|PATA_ATIIXP|PATA_ATP867X|PATA_CMD64X|PATA_CS5520|PATA_CS5530|PATA_CS5535|PATA_CS5536|PATA_CYPRESS|PATA_EFAR|PATA_HPT366|PATA_HPT37X|PATA_HPT3X2N|PATA_HPT3X3|PATA_IT8213|PATA_IT821X|PATA_JMICRON|PATA_MARVELL|PATA_MPIIX|PATA_OLDPIIX|PATA_OPTIDMA|PATA_PDC2027X|PATA_PDC_OLD|PATA_RADISYS|PATA_RDC|PATA_SCH|PATA_SERVERWORKS|PATA_SIL680|PATA_SIS|PATA_TOSHIBA|PATA_TRIFLEX|PATA_VIA|PATA_WINBOND)=.*/# CONFIG_\1 is not set/'
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
