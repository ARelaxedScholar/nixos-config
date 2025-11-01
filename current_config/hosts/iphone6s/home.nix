{
  config,
  pkgs,
  inputs,
  ...
}:

{
  imports = [
    #inputs.walker.homeManagerModules.walker
    ../../modules/walker.nix
  ];

  home.packages = with pkgs; [
    tree
    obs-studio
    mpv
    anki
    obsidian
    reaper
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
