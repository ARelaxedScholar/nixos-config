{
  config,
  pkgs,
  lib,
  ...
}:
let
  # Define your preferred programs here
  terminal = "${pkgs.kitty}/bin/kitty";
  browser = "${pkgs.firefox}/bin/firefox";
  launcher = "${pkgs.rofi}/bin/rofi";
  fileManager = "${pkgs.kdePackages.dolphin}/bin/dolphin";
in
{
  home.packages = with pkgs; [
    rofi
    grim  # for screenshots
    slurp # for area selection
  ];

   xdg.configFile."niri/config.kdl" = {
     force = true;
     text = ''
       input {
           keyboard {
               xkb {
                   layout "us"
               }
           }
           
           touchpad {
               tap
               natural-scroll
               accel-speed -0.3
               accel-profile "flat"
           }
        }





        layout {
            gaps 16
            center-focused-column "never"
        }
      //xwayland "enable"

       // Run the daily wallpaper selector script at startup
       spawn-at-startup "set-daily-wallpaper"

       binds {
           // Program launchers
            Mod+Space { spawn "${launcher}" "-show" "drun"; }
            Mod+Return { spawn "${terminal}"; }
            Mod+E { spawn "${browser}"; }
            Mod+F { spawn "${fileManager}"; }
           
           // Window management
            Mod+Q { close-window; }
            Mod+Shift+Q { quit; }

           // Focus movement
           Mod+H { focus-column-left; }
           Mod+L { focus-column-right; }
           Mod+Left { focus-column-left; }
           Mod+Right { focus-column-right; }

           // Move windows
           Mod+Shift+H { move-column-left; }
           Mod+Shift+J { move-window-down; }
           Mod+Shift+K { move-window-up; }
           Mod+Shift+L { move-column-right; }

           Mod+Shift+Left { move-column-left; }
           Mod+Shift+Down { move-window-down; }
           Mod+Shift+Up { move-window-up; }
           Mod+Shift+Right { move-column-right; }

           // Workspaces - focus
           Mod+1 { focus-workspace 1; }
           Mod+2 { focus-workspace 2; }
           Mod+3 { focus-workspace 3; }
           Mod+4 { focus-workspace 4; }
           Mod+5 { focus-workspace 5; }
           Mod+6 { focus-workspace 6; }
           Mod+7 { focus-workspace 7; }
           Mod+8 { focus-workspace 8; }
           Mod+9 { focus-workspace 9; }
           Mod+J { focus-workspace-down; }
           Mod+K { focus-workspace-up; }
           Mod+Down { focus-workspace-down; }
           Mod+Up { focus-workspace-up; }

           // Workspaces - move window to
           Mod+Shift+1 { move-column-to-workspace 1; }
           Mod+Shift+2 { move-column-to-workspace 2; }
           Mod+Shift+3 { move-column-to-workspace 3; }
           Mod+Shift+4 { move-column-to-workspace 4; }
           Mod+Shift+5 { move-column-to-workspace 5; }
           Mod+Shift+6 { move-column-to-workspace 6; }
           Mod+Shift+7 { move-column-to-workspace 7; }
           Mod+Shift+8 { move-column-to-workspace 8; }
           Mod+Shift+9 { move-column-to-workspace 9; }

           // Screenshots
             Print { spawn "${pkgs.grim}/bin/grim" "-g" "$(${pkgs.slurp}/bin/slurp)" "$(xdg-user-dir PICTURES)/$(date +screenshot_%Y-%m-%d-%H%M%S.png)"; }
             Mod+Print { spawn "${pkgs.grim}/bin/grim" "$(xdg-user-dir PICTURES)/$(date +screenshot_%Y-%m-%d-%H%M%S.png)"; }

           // Media keys
            XF86AudioRaiseVolume { spawn "${pkgs.wireplumber}/bin/wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "0.1+"; }
            XF86AudioLowerVolume { spawn "${pkgs.wireplumber}/bin/wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "0.1-"; }
            XF86AudioMute { spawn "${pkgs.wireplumber}/bin/wpctl" "set-mute" "@DEFAULT_AUDIO_SINK@" "toggle"; }
           
           // Fullscreen
            Mod+Shift+F { fullscreen-window; }
       }
     '';
  };
}