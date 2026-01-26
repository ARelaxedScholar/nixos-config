{ pkgs, ... }:
{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    profileExtra = ''
      if [ -z "$DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
        export DISPLAY=":0"
        export XAUTHORITY="$HOME/.Xauthority"
        export ELECTRON_OZONE_PLATFORM="wayland"
        export ELECTRON_OZONE_PLATFORM_HINT="auto"
        export QT_QPA_PLATFORM="wayland"
        export GDK_BACKEND="wayland,x11"
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
