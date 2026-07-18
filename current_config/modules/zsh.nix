{ pkgs, ... }:
{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    profileExtra = ''
      if [ -z "$WAYLAND_DISPLAY" ] && [ -z "$DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
        export XDG_SESSION_TYPE="wayland"
        export XDG_CURRENT_DESKTOP="Niri"
        export XDG_SESSION_DESKTOP="Niri"
        export ELECTRON_OZONE_PLATFORM="wayland"
        export ELECTRON_OZONE_PLATFORM_HINT="auto"
        export QT_QPA_PLATFORM="wayland"
        export GDK_BACKEND="wayland,x11"
        if [ -z "$DBUS_SESSION_BUS_ADDRESS" ]; then
          exec dbus-run-session niri --session
        else
          exec niri --session
        fi
      fi

      eval "$(zoxide init zsh)"
    '';

    shellAliases = {
      ll = "ls -la";
      gpu = "git push";
      pkc = "pkill -9 cargo";
      kc = "kilocode";
      oc = "opencode";
      gem = "gemini";
    };

    oh-my-zsh = {
      enable = true;
    };
  };
}
