{ config, pkgs, lib, ... }:
with lib;

{
  users.groups.nrz = {};
  users.users.nrz = {
    group = "nrz";
    isNormalUser= true;
    createHome = true;
    home = "/home/nrz";
    extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC55W6PKm7SBa2SNT2pCh8K6ZbVRf32ip3Q/zxHSDwS8ljRtIU2RdpMOrwIJ6KmxkWFp0ZIETn6vB8HT9C9LXVPeNAdAzeIOcmicmK1xiH7w4bXJegVa+8V9EQYsFNB1OYWmCXfh6O7TLGzot+LnHvyCv3BV5hNbAEYyQq8RnYkDZb57aebNgx1tzpYsa74n8VIUB4nia5v9SpnyDjZfrCXSY/XxNq8FjDbeJV6+rcg2XnhsvnC/Rv/2jQmQ2bSxQF9KGUgC22k2xg5THXSYH4VGBiZhSTeve9ZniIcdxGwAvecVtbGHf/V4DXqIVbLXmuGu+Kge854dKMzgqTuFG+Iteh7aO3+LKgowc7lXfRWuwlxyBsMM5+xCX86pQr9TYwtGMPpdUL6XAb28xFJ8ajT+Ql9vu+ei+oQWE3l8fWxT49vhtlgLMeaHo0ttBaUB96FgS+qibN/Qa+fuQGKsuMS5QvsYHTNVKcW5F6QcP30VipG3s65SYBxXpGN8Jg7yQsfPUlKfz/Qu7UkXdy34a4H3g8KkaCpRXn7aP5FPVyLOfwVt/kNdxjv5rQWSwz7gVcaHDAtVfS4+JzT6OKHotyAl0KtsAqVI+pSPJk4zXIixKquOuaERwCq4PXZ1rIN8hxbHWDbdMUkM5O8ILCzB4l+cBkzXgk27dsFSTkoXfGdCw== nerzhul@Nerz-PC"
    ];
    packages = with pkgs; [ ]; # I assume this can be removed, but not sure
  };

  security.sudo.extraRules = [{
    users = [ "nrz" ];
    commands = [
      { command = "ALL" ;
         options= [ "NOPASSWD" ]; # "SETENV" # Adding the following could be a good idea
      }
    ];
  }];
}
