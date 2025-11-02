{
  config,
  pkgs,
  inputs,
  ...
}:

{
  imports = [
    #inputs.walker.homeManagerModules.walker
    ../../modules/hyprland.nix
    ../../modules/zed.nix
  ];

  home.packages = with pkgs; [
    tree
    obs-studio
    mpv
    anki
    obsidian
    reaper
    # fonts
    noto-fonts-cjk-sans # <for chinese, japanese, korean
    ipafont
    kochi-substitute
    noto-fonts
    noto-fonts-color-emoji
    wofi
    kdePackages.dolphin
  ];

  services = {
    # blue light filter
    gammastep = {
      enable = true;
      provider = "manual";
      latitude = 45.32;
      longitude = 77.88;
    };
  };

  home.stateVersion = "25.05";
}
