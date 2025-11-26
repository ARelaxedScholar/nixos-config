{ pkgs, ... }:
{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    profileExtra = ''
      if [ -z "$DISPLAY" ] && [ "$XDG_VTNR" -eq 1 ]; then
        exec niri --session
      fi
    '';

    shellAliases = {
      ll = "ls -la";
    };

    oh-my-zsh = {
      enable = true;
    };
  };
}
