{ pkgs ? import <nixpkgs> { },
}:

pkgs.mkShell {
  LOCALE_ARCHIVE = "${pkgs.glibcLocales}/lib/locale/locale-archive";
  env.LANG = "C.UTF-8";
  env.LC_ALL = "C.UTF-8";

  packages = [
    # For nix-prefetch-url
    pkgs.nix
  ];
  shellHook = ''
  '';
}
