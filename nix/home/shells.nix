{ config, lib, pkgs, ... }:

{
  home.packages = with pkgs; [
    exa
  ];

  programs.fish = {
    enable = true;
    shellAliases = {
      l = "exa";
      ls = "exa";
      copy = "xclip -i -selection clipboard";
      g = "git";
      e = "eval $EDITOR";
      ee = "e (fzf)";
      download = "aria2c --file-allocation=none --seed-time=0";
      chromecast = "castnow --address 192.168.2.64 --myip 192.168.2.76";
      gotty-sridca = "gotty -a 0.0.0.0 -p 9999 -r"; # To be run from the thebeast wireguard peer only.
    };
  };

  programs.bash = {
    enable = true;
    historyIgnore = [ "l" "ls" "cd" "exit" ];
    historyControl = [ "erasedups" ];
    enableAutojump = true;
    shellAliases = {
      l = "exa";
      ls = "exa";
      copy = "xclip -i -selection clipboard";
      g = "git";
      e = "$EDITOR";
      ee = "e $(fzf)";
      download = "aria2c --file-allocation=none --seed-time=0";
      chromecast = "castnow --address 192.168.2.64 --myip 192.168.2.76";
    };
    initExtra = ''
    if [ -e ~/.nix-profile/etc/profile.d/nix.sh ]; then
      . ~/.nix-profile/etc/profile.d/nix.sh;
      export NIX_PATH=$HOME/.nix-defexpr/channels''${NIX_PATH:+:}$NIX_PATH
    fi # added by Nix installer
    '';
  };

  programs.fzf = {
    enable = true;
    enableBashIntegration = true;
  };
}