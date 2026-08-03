{ config, pkgs, lib, ... }:

let
  modDirVersion = "6.1.63";
  tag = "stable_20231123";

  # Définition de la dérivation du noyau Linux RPi5
  linux_rpi5 = (pkgs.buildLinux {
    version = "${modDirVersion}-${tag}";
    inherit modDirVersion;

    src = pkgs.fetchFromGitHub {
      owner = "raspberrypi";
      repo = "linux";
      rev = tag;
      hash = "sha256-4Rc57y70LmRFwDnOD4rHoHGmfxD9zYEAwYm9Wvyb3no=";
    };

    # See https://gitlab.com/vriska/nix-rpi5/-/blob/main/linux-rpi.nix?ref_type=heads
    # specific to RPI5
    defconfig = "bcm2712_defconfig";

    kernelPatches = with pkgs.kernelPatches; [
      bridge_stp_helper
      request_key_helper
    ];

    features = {
      efiBootStub = false;
    };

    extraMeta = {
      platforms = with lib.platforms; arm ++ aarch64;
      hydraPlatforms = [ "aarch64-linux" ];
    };
  }).overrideAttrs (oldAttrs: {
    postConfigure = ''
      # Empêche la présence de '-v7' ou autre suffixe qui altèrerait le modDirVersion
      sed -i $buildRoot/.config -e 's/^CONFIG_LOCALVERSION=.*/CONFIG_LOCALVERSION=""/'
      sed -i $buildRoot/include/config/auto.conf -e 's/^CONFIG_LOCALVERSION=.*/CONFIG_LOCALVERSION=""/'
    '';

    # Duplication des fichiers DTB pour assurer la compatibilité U-Boot
    postFixup = ''
      dtbDir=${if pkgs.stdenv.isAarch64 then "$out/dtbs/broadcom" else "$out/dtbs"}
      rm -f $dtbDir/bcm283*.dtb
      copyDTB() {
        if [ -f "$dtbDir/$1" ]; then
          cp -v "$dtbDir/$1" "$dtbDir/$2"
        fi
      }
    '' + lib.optionalString (lib.elem pkgs.stdenv.hostPlatform.system [ "armv7l-linux" "aarch64-linux" ]) ''
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
  # Injection des paquets de noyau personnalisés dans le système
  boot.kernelPackages = pkgs.linuxPackagesFor linux_rpi5;
}
