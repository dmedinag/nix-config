# NixOS on Thinkpad P71

# NixOS 17.09 works, but upgrading to nixos-unstable gets you:
#  - Working DPI in Chrome
#  - Trackpoint scroll

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      /etc/nixos/hardware-configuration.nix
      ./nix/base.nix
      ./nix/emacs.nix
      ./nix/gui.nix
      ./nix/dev.nix
    ];

  # EFI boot
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "thebeast"; # Define your hostname.

  # WiFi
  # Connect to wifi using nmtui / nmcli.
  networking.networkmanager.enable = true;

  services.openssh.enable = true;

  sound.mediaKeys.enable = true;

  # services.xserver.
  services.xserver = {
    # Enable touchpad support.
    libinput.enable = true;

    # Nvidia
    # Note: nvidia card must be enabled in BIOS.
    videoDrivers = [ "nvidia" ];

    # Configuration for the LG UltraFine 5k monitor.
    # Facts:
    #  - TwinView is automatically enabled in recent nvidia drivers (no need to enable it explicitly)
    #  - nvidiaXineramaInfo must be disabled, otherwise xmonad will treat the display as two monitors.
    screenSection = ''
      Option "MetaModes"           "DP-5: 2560x2880, DP-3: 2560x2880"
      Option "ConnectedMonitor"    "DP-5, DP-3"
      Option "MetaModeOrientation" "DP-3 RightOf DP-5"
      Option "nvidiaXineramaInfo"  "false"
    '';
    # Not sure if this is still required.
    serverFlagsSection = ''
      Option  "Xinerama" "0"
    '';
  };
  # TODO: xrandr switch? (autoxrandr)

  # For occasions when xmonad is broken.
  services.xserver.desktopManager.plasma5.enable = true;
  services.xserver.displayManager.lightdm.enable = true;

  # TLP Linux Advanced Power Management
  services.tlp.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.extraUsers.srid = {
    isNormalUser = true;
    uid = 1000;
    extraGroups = [ "wheel" "networkmanager" ];
  };

  # This value determines the NixOS release with which your system is to be
  # compatible, in order to avoid breaking some software such as database
  # servers. You should change this only after NixOS release notes say you
  # should.
  system.stateVersion = "17.09"; # Did you read the comment?

}
