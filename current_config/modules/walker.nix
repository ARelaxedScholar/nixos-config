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
    };
  };

}
