{ pkgs, ... }:
{
  programs.walker = {
    enable = true;
    runAsService = true;

    config = {
      theme = "Acnologia";
      placeholders."default" = {
        input = "Search";
        list = "Example";
      };
      providers.prefixes = [
        {
          provider = "websearch";
          prefix = "+";
        }
        {
          provider = "providerlist";
          prefix = "_";
        }
      ];
      keybinds.quick_activate = [
        "F1"
        "F2"
        "F3"
      ];
      modules = [
        "applications"
        "calculator"
        "files"
        "runner"
        "websearch"
        "clipboard"
      ];
    };
  };
  nix.settings = {
    extra-substituters = [
      "https://walker.cachix.org"
      "https://walker-git.cachix.org"
    ];
    extra-trusted-public-keys = [
      "walker.cachix.org-1:fG8q+uAaMqhsMxWjwvk0IMb4mFPFLqHjuvfwQxE4oJM="
      "walker-git.cachix.org-1:vmC0ocfPWh0S/vRAQGtChuiZBTAe4wiKDeyyXM0/7pM="
    ];
  };

}
