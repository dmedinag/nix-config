# NixOS on Thinkpad P71

{ config, pkgs, ... }:

let
  # sridca = (import /home/srid/code/srid.ca {port = "9005";});
in
{
  imports =
    [ <nixos-hardware/lenovo/thinkpad>
      /etc/nixos/hardware-configuration.nix
      ./nix/base.nix
      ./nix/emacs.nix
      ./nix/gui.nix
      ./nix/dev.nix
      ./nix/srid-home.nix
      ./myobsidian/myobsidian.nix  # Work configuration (private)
    ];

  # systemd.services.sridcatmp = sridca.unit;

  # EFI boot
  boot.cleanTmpDir = true;
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.plymouth.enable = false;

  networking.hostName = "thebeast"; # Define your hostname.

  # Always use the latest available kernel.
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # WiFi
  # Connect to wifi using nmtui / nmcli.
  networking.networkmanager.enable = true;

  # Wireguard client
  networking.wireguard.interfaces = {
    wg0 = {
      ips = [ "10.100.0.2/24" ];
      privateKeyFile = "/home/srid/wireguard-keys/private";
      peers = [
        { publicKey = "8BLMztljWIV+9V+fXgj34GCVn0YSK6PYdAuPVkdidTs=";
          # allowedIPs = [ "0.0.0.0/1" ];
          allowedIPs = [ "10.100.0.1" "104.198.14.52" ];
          endpoint = "facade.srid.ca:51820";
          persistentKeepalive = 25;
        }
      ];
    };
  };

  # TLP Linux Advanced Power Management
  # Seems to make suspend / wake-up work on lid-close.
  services.tlp.enable = true;

  # This machine is now a long-running home-server with a bluetooth keyboard
  services.logind.extraConfig = ''
    HandleLidSwitch=ignore
  '';

  # Want to ssh to thinkpad from macbook
  services.openssh.enable = true;
  services.openssh.ports = [22 9812];

  services.timesyncd.enable = true;

  sound.mediaKeys.enable = true;

  services.ddclient = {
    enable = false;  # FIXME: has issues
    configFile = "/home/srid/.ddclient";
  };

  services.nginx = {
    enable = true;
    user = "srid";
  };

  services.postgresql = {
    enable = false;
    # package = pkgs.postgresql_10;  -- not available on 18.09
    enableTCPIP = true;
    # https://nixos.wiki/wiki/PostgreSQL
    authentication = pkgs.lib.mkOverride 10 ''
      local all all trust
      host all all ::1/128 trust
    '';
    initialScript = pkgs.writeText "backend-initScript" ''
      CREATE ROLE nixcloud WITH LOGIN PASSWORD 'nixcloud' CREATEDB;
      CREATE DATABASE nixcloud;
      GRANT ALL PRIVILEGES ON DATABASE nixcloud TO nixcloud;
    '';
  };

  # When using just discrete graphics with nvidia, DPI is calculated
  # automatically,
  # https://http.download.nvidia.com/XFree86/Linux-x86/1.0-8178/README/appendix-y.html

  # services.xserver.
  services.xserver = {
    # Enable touchpad support.
    libinput.enable = true;
    multitouch = {
      enable = true;
      invertScroll = true;
    };

    # Graphics drivers.
    videoDrivers = [ "nvidia" "intel" ];
    # Nvidia detects somehow higher value for a DPI than what is standard for retina. Set it manually:
    # Same as iMac retina 5k https://en.wikipedia.org/wiki/Retina_Display#Models
    dpi = 218;

    # Configuration for high res (4k/5k) monitors that use dual channel.
    # Facts:
    #  - TwinView is automatically enabled in recent nvidia drivers (no need to enable it explicitly)
    #  - nvidiaXineramaInfo must be disabled, otherwise xmonad will treat the display as two monitors.
    screenSection = ''
      Option "nvidiaXineramaInfo"  "false"
    '';

    # FIXME: To work with varied display configurations, I have to use `arandr`.
    # For example, to manual display the laptop screen when connected to
    # external display. This needs to be streamlined.

    # Not sure if this is still required.
    serverFlagsSection = ''
      Option  "Xinerama" "0"
    '';
  };

  environment.systemPackages = with  pkgs; [
    # TODO: Use autorandr to switch between modes.
    # For now, doing it manually using arandr.
    #   Using .screenlayout/lgonly.sh when connecting the monitor
    arandr
    autorandr
    acpi
    # pulsemixer
    # https://github.com/GeorgeFilipkin/pulsemixer#interactive-mode
    # H/L, Shift+Left/Shift+Right   change volume by 10
    # 1/2/3/4/5/6/7/8/9/0           set volume to 10%-100%
    # m                             mute/unmute
    # Mouse wheel                   volume change
    # TODO: Configure xmonad to bring pulsemixer on popup
    # as needed.
    pulsemixer
    blueman
    # Casting local videos 
    nodePackages.castnow
  ];

  hardware = {
    # TODO: Hybrid graphics.
    #  - Bumblee works, but DPI sucks (no nvidia driver to detect it)
    #  - Connect to external monitor using `optirun true; intel-virtual-output -f` (and arandr)
    #  - Somewhat sluggish performance; monitor 2 duplicates often.
    bumblebee = {
      enable = false;
      driver = "nvidia";
      pmMethod = "none";
      connectDisplay = true;
    };

    # Audio
    # Use `pactl set-sink-volume 0 +10%` to increase volume.
    pulseaudio = {
      enable = true;
      package = pkgs.pulseaudioFull;
      support32Bit = true;
      daemon.config = {
        flat-volumes = "no";
      };
    };

    opengl = {
      enable = true;
      driSupport = true;
      driSupport32Bit = true;
    };

    # Bluetooth
    # https://nixos.wiki/wiki/Bluetooth
    bluetooth = {
      enable = true;
      # For Bose QC 35
      extraConfig = "
        [General]
        Enable=Source,Sink,Media,Socket
      ";
    };
  };

  users.extraUsers.srid = {
    isNormalUser = true;
    uid = 1000;
    extraGroups = [ "wheel" "networkmanager" "audio" "lxd" ];
  };

  # This value determines the NixOS release with which your system is to be
  # compatible, in order to avoid breaking some software such as database
  # servers. You should change this only after NixOS release notes say you
  # should.
  system.stateVersion = "18.09"; # Did you read the comment?
}
