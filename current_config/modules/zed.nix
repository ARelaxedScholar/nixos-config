{
  pkgs,
  lib,
  ...
}:
{
  programs.zed-editor = {
    enable = true;
    extensions = [
      "nix"
      "toml"
      "lua"
      "basher"
      "dracula"
    ];
    extraPackages = [ pkgs.nixd ];

    userSettings = {
      # Use Zed's built-in file picker instead of system portal
      use_system_path_prompts = false;

      vim_mode = true;
      vim = {
        use_system_clipboard = "always";
        use_multiline_find = true;
        enable_vim_sneak = true;
      };
      theme = "Dracula";
      ui_font_size = lib.mkForce 12;
      buffer_font_size = lib.mkForce 14;
      relative_line_numbers = true;
      file_finder = {
        modal_width = "medium";
      };
      tab_bar = {
        show = true;
      };
      tabs = {
        show_diagnostics = "errors";
      };
      indent_guides = {
        enabled = true;
        coloring = "indent_aware";
      };
      inlay_hints = {
        enabled = true;
      };
      inactive_opacity = "0.5";
      auto_install_extensions = true;
      outline_panel = {
        dock = "right";
      };
      collaboration_panel = {
        dock = "left";
      };
      notification_panel = {
        dock = "left";
      };
      chat_panel = {
        dock = "left";
      };

      assistant = {
        enabled = false;
        version = "2";
        default_open_ai_model = null;

        default_model = {
          provider = "zed.dev";
          model = "claude-3-5-sonnet-latest";
        };
      };

      node = {
        path = lib.getExe pkgs.nodejs_22;
        npm_path = lib.getExe' pkgs.nodejs_22 "npm";
      };

      hour_format = "hour12";
      auto_update = false;
      terminal = {
        alternate_scroll = "off";
        blinking = "off";
        copy_on_select = false;
        dock = "bottom";
        detect_venv = {
          on = {
            directories = [
              ".env"
              "env"
              ".venv"
              "venv"
            ];
            activate_script = "default";
          };
        };
        env = {
          EDITOR = "zed --wait";
          TERM = "kitty";
        };
        font_family = "FiraCode Nerd Font Mono";
        font_features = null;
        line_height = "comfortable";
        option_as_meta = false;
        button = false;
        shell = { program = "${pkgs.zsh}/bin/zsh"; args = ["-l"]; };
        toolbar = {
          title = true;
        };
        working_directory = "current_project_directory";
      };
      file_types = {
        JSON = [
          "json"
          "jsonc"
          "*.code-snippets"
        ];
      };
      languages = {
        Markdown = {
          formatter = "prettier";
        };
        JSON = {
          formatter = "prettier";
        };
        TOML = {
          formatter = "taplo";
        };
      };

      lsp = {
        nix = {
          binary = {
            path_lookup = true;
          };
        };

        "rust-analyzer" = {
          binary = {
            path_lookup = true;
          };
          settings = {
            diagnostics = {
              enable = true;
              styleLints = {
                enable = true;
              };
            };
            checkOnSave = true;
            check = {
              command = "clippy";
              features = "all";
            };
            cargo = {
              buildScripts = {
                enable = true;
              };
              features = "all";
            };
            inlayHints = {
              bindingModeHints = {
                enable = true;
              };
              closureStyle = "rust_analyzer";
              closureReturnTypeHints = {
                enable = "always";
              };
              discriminantHints = {
                enable = "always";
              };
              expressionAdjustmentHints = {
                enable = "always";
              };
              implicitDrops = {
                enable = true;
              };
              lifetimeElisionHints = {
                enable = "always";
              };
              rangeExclusiveHints = {
                enable = true;
              };
            };
            procMacro = {
              enable = true;
            };
            rustc = {
              source = "discover";
            };
            files = {
              excludeDirs = [
                ".cargo"
                ".direnv"
                ".git"
                "node_modules"
                "target"
              ];
            };
          };
        };

        settings = {
          dialyzerEnabled = true;
        };
      };
    };

    userKeymaps = [
      {
        context = "Editor && (vim_mode == normal || vim_mode == visual)";
        bindings = {
          "space g h d" = "editor::ToggleHunkDiff";
          "space g h r" = "editor::RevertSelectedHunks";
          "space t i" = "editor::ToggleInlayHints";
          "space u w" = "editor::ToggleSoftWrap";
          "space c z" = "workspace::ToggleCenteredLayout";
          "space m p" = "markdown::OpenPreview";
          "space m P" = "markdown::OpenPreviewToTheSide";
          "space f p" = "projects::OpenRecent";
          "space f m" = "editor::Format";
          "space f M" = "editor::FormatSelections";
          "space s w" = "pane::DeploySearch";
          "space a c" = "assistant::ToggleFocus";
          "g f" = "editor::OpenExcerpts";
        };
      }
      {
        context = "Editor && vim_mode == normal && !VimWaiting && !menu";
        bindings = {
          "ctrl-h" = "workspace::ActivatePaneLeft";
          "ctrl-l" = "workspace::ActivatePaneRight";
          "ctrl-k" = "workspace::ActivatePaneUp";
          "ctrl-j" = "workspace::ActivatePaneDown";
          "space c a" = "editor::ToggleCodeActions";
          "space ." = "editor::ToggleCodeActions";
          "space c r" = "editor::Rename";
          "g d" = "editor::GoToDefinition";
          "g D" = "editor::GoToDefinitionSplit";
          "g i" = "editor::GoToImplementation";
          "g I" = "editor::GoToImplementationSplit";
          "g t" = "editor::GoToTypeDefinition";
          "g T" = "editor::GoToTypeDefinitionSplit";
          "g r" = "editor::FindAllReferences";
          "] d" = "editor::GoToDiagnostic";
          "[ d" = "editor::GoToPrevDiagnostic";
          "] e" = "editor::GoToDiagnostic";
          "[ e" = "editor::GoToPrevDiagnostic";
          "s s" = "outline::Toggle";
          "s S" = "project_symbols::Toggle";
          "space x x" = "diagnostics::Deploy";
          "] h" = "editor::GoToHunk";
          "[ h" = "editor::GoToPrevHunk";
          "shift-h" = "pane::ActivatePrevItem";
          "shift-l" = "pane::ActivateNextItem";
          "shift-q" = "pane::CloseActiveItem";
          "ctrl-q" = "pane::CloseActiveItem";
          "space b d" = "pane::CloseActiveItem";
          "space b o" = "pane::CloseInactiveItems";
          "ctrl-s" = "workspace::Save";
          "space space" = "file_finder::Toggle";
          "space /" = "pane::DeploySearch";
          "space e" = "pane::RevealInProjectPanel";
        };
      }
      {
        context = "EmptyPane || SharedScreen";
        bindings = {
          "space space" = "file_finder::Toggle";
          "space f p" = "projects::OpenRecent";
        };
      }
      {
        context = "Editor && vim_mode == visual && !VimWaiting && !menu";
        bindings = {
          "g c" = "editor::ToggleComments";
        };
      }
      {
        context = "Editor && vim_mode == insert && !menu";
        bindings = {
          "j j" = "vim::NormalBefore";
          "j k" = "vim::NormalBefore";
        };
      }
      {
        context = "Editor && vim_operator == c";
        bindings = {
          "c" = "vim::CurrentLine";
          "a" = "editor::ToggleCodeActions";
        };
      }
      {
        context = "Workspace";
        bindings = {
          "ctrl-\\" = "terminal_panel::ToggleFocus";
        };
      }
      {
        context = "Terminal";
        bindings = {
          "ctrl-h" = "workspace::ActivatePaneLeft";
          "ctrl-l" = "workspace::ActivatePaneRight";
          "ctrl-k" = "workspace::ActivatePaneUp";
          "ctrl-j" = "workspace::ActivatePaneDown";
        };
      }
      {
        context = "ProjectPanel && not_editing";
        bindings = {
          "a" = "project_panel::NewFile";
          "A" = "project_panel::NewDirectory";
          "r" = "project_panel::Rename";
          "d" = "project_panel::Delete";
          "x" = "project_panel::Cut";
          "c" = "project_panel::Copy";
          "p" = "project_panel::Paste";
          "q" = "workspace::ToggleRightDock";
          "space e" = "workspace::ToggleRightDock";
          "ctrl-h" = "workspace::ActivatePaneLeft";
          "ctrl-l" = "workspace::ActivatePaneRight";
          "ctrl-k" = "workspace::ActivatePaneUp";
          "ctrl-j" = "workspace::ActivatePaneDown";
        };
      }
      {
        context = "Dock";
        bindings = {
          "ctrl-w h" = "workspace::ActivatePaneLeft";
          "ctrl-w l" = "workspace::ActivatePaneRight";
          "ctrl-w k" = "workspace::ActivatePaneUp";
          "ctrl-w j" = "workspace::ActivatePaneDown";
        };
      }
      {
        context = "Workspace";
        bindings = {
          "ctrl-b" = "workspace::ToggleRightDock";
        };
      }
    ];
  };
}
