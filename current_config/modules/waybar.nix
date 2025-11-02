{ pkgs, ... }:

{
  programs.waybar = {
    enable = true;
    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        height = 30;
        modules-left = [
          "hyprland/workspaces"
          "hyprland/window"
        ];
        modules-center = [ "clock" ];
        modules-right = [
          "pulseaudio"
          "network"
          "cpu"
          "memory"
          "battery"
        ];

        # Module-specific settings
        "hyprland/workspaces" = {
          format = "{icon}";
          on-click = "activate";
        };
        "pulseaudio" = {
          format = "{volume}% {icon}";
          tooltip = false;
          "on-click" = "pavucontrol";
        };
        "network" = {
          format-wifi = "{essid} ({signalStrength}%) ";
          format-ethernet = "{ipaddr}/{cidr} ";
          format-disconnected = "Disconnected ⚠";
        };
        "battery" = {
          states = {
            warning = 30;
            critical = 15;
          };
          format = "{capacity}% {icon}";
          format-charging = "{capacity}% ";
          format-plugged = "{capacity}% ";
          format-alt = "{time} {icon}";
        };
      };
    };

    style = ''
      * {
        font-family: FontAwesome, Noto Sans;
        font-size: 13px;
      }

      window#waybar {
        background-color: rgba(43, 48, 59, 0.5);
        border-bottom: 3px solid rgba(100, 114, 125, 0.5);
        color: #ffffff;
      }

      #workspaces button {
        padding: 0 5px;
        background-color: transparent;
        color: #ffffff;
      }

      #workspaces button.active {
        background-color: #64727D;
      }
    '';
  };

}
