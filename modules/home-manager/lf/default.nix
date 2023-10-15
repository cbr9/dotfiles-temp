{
  pkgs,
  config,
  lib,
  ...
}:
with lib; let
  mkLfCmd = cmd: ''
    %{{
      ${cmd}
    }}
  '';
  mkShellCmd = cmd: ''
    ''${{
      ${cmd}
    }}
  '';
  mkAsyncCmd = cmd: ''
    &{{
      ${cmd}
    }}
  '';
  cfg = config.programs.lf;
in {
  programs.fish = mkIf cfg.enable {
    functions.fish_user_key_bindings = ''
      bind \cw 'set old_tty (stty -g); stty sane; lfcd; stty $old_tty; commandline -f repaint'
    '';
  };

  home.shellAliases = mkIf cfg.enable {
    lf = "lfcd";
  };

  xdg.desktopEntries.lf = mkIf (cfg.enable && (builtins.hasAttr "TERMINAL" config.home.sessionVariables)) {
    name = "lf";
    genericName = "lf";
    type = "Application";
    exec = "${config.home.sessionVariables.TERMINAL} -e ${cfg.package}/bin/lf";
    icon = "utilities-terminal";
    terminal = false;
    categories = ["ConsoleOnly" "System" "FileTools" "FileManager"];
    mimeType = ["inode/directory"];
  };

  xdg.configFile = {
    "fish/functions/lfcd.fish" = {
      enable = config.programs.fish.enable && cfg.enable;
      source = pkgs.fetchurl {
        url = "https://raw.githubusercontent.com/gokcehan/lf/master/etc/lfcd.fish";
        sha256 = "sha256-wn9YEPtMqSHq7Ahr3KmG1YogiJQvKBOAO61pdPH6Pf0=";
      };
    };
    "fish/completions/lf.fish" = {
      enable = config.programs.fish.enable && cfg.enable;
      source = pkgs.fetchurl {
        url = "https://raw.githubusercontent.com/gokcehan/lf/master/etc/lf.fish";
        sha256 = "sha256-jbcVK/MnthW08MM3bN0D439SZJdBvzRgf1TUGcgYDxE=";
      };
    };
    "lf/icons" = {
      enable = cfg.enable;
      source = pkgs.fetchurl {
        url = "https://raw.githubusercontent.com/gokcehan/lf/master/etc/icons.example";
        sha256 = "sha256-QbWr5FxJZ5cJqS4zg+qyNK8JUG6SdLmaFoBuFXi0q0M=";
      };
    };
    "lf/colors" = {
      enable = cfg.enable;
      source = pkgs.fetchurl {
        url = "https://raw.githubusercontent.com/gokcehan/lf/master/etc/colors.example";
        sha256 = "sha256-cYJlXuRjuotQ1aynPG5+UGK2nBBNg/6xRiGs2mBpKeY=";
      };
    };
  };

  home.packages = with pkgs;
    lib.mkIf cfg.enable [
      libreoffice-qt
      ctpv
      unzip
      atool # for archive files
      bat
      chafa # for image files on Wayland
      delta # for diff files
      ffmpeg_6-full
      ffmpegthumbnailer
      fontforge
      glow # for markdown files
      imagemagick
      jq # for json files
      transmission
    ];

  xdg.configFile."ctpv/config" = {
    enable = cfg.enable && cfg.previewer.source == "${pkgs.ctpv}/bin/ctpv";
    text = ''
      set forcekitty
      set forcekittyanim
    '';
  };

  programs.lf = {
    enable = true;
    settings = {
      icons = true;
      hidden = true;
      ignorecase = true;
      incsearch = true;
    };
    commands = {
      drag-and-drop = mkLfCmd "${pkgs.xdragon}/bin/dragon --all --and-exit --on-top $fx";

      toggle-preview = (
        mkLfCmd
        # bash
        ''
          if [ "$lf_preview" = "true" ]; then
              lf -remote "send $id :set preview false; set ratios 1:5"
          else
              lf -remote "send $id :set preview true; set ratios 1:2:3"
          fi
        ''
      );

      fzf-search = (
        mkShellCmd
        # bash
        ''
          RG_PREFIX="rg --no-column --no-line-number --no-heading --multiline --trim --color=always --smart-case "
          res="$(
            FZF_DEFAULT_COMMAND="$RG_PREFIX \'\'" \
              fzf --bind "change:reload:$RG_PREFIX {q} || true" \
              --ansi --layout=reverse --header 'Search in files' \
              | cut -d':' -f1 | sed 's/\\/\\\\/g;s/"/\\"/g'
          )"
          [ -n "$res" ] && lf -remote "send $id select \"$res\""
        ''
      );

      follow-link = (
        mkLfCmd
        # bash
        ''
          lf -remote "send ''${id} select '$(readlink $f)'"
        ''
      );

      fzf-jump = (
        mkShellCmd
        # bash
        ''
          res="$(fd --max-depth 3 --hidden | ${pkgs.skim}/bin/sk --reverse --header='Jump to location')"
          if [ -n "$res" ]; then
              if [ -d "$res" ]; then
                  cmd="cd"
              else
                  cmd="select"
              fi
              res="$(printf '%s' "$res" | sed 's/\\/\\\\/g;s/"/\\"/g')"
              lf -remote "send $id $cmd \"$res\""
          fi
        ''
      );

      on-cd = (
        mkAsyncCmd
        # bash
        ''
          # '&' commands run silently in background (which is what we want here),
          # but are not connected to stdout.
          # To make sure our escape sequence still reaches stdout we pipe it to /dev/tty
          printf "\033]0; $(pwd | sed "s|$HOME|~|") - lf\007" > /dev/tty
        ''
      );
      open = (
        mkShellCmd
        # bash
        ''
          case $(file --mime-type -Lb "$fx") in
              text/*) $EDITOR "$fx";;
              application/json) $EDITOR "$fx";;
              image/*) ${pkgs.feh}/bin/feh "$fx";;
              application/gzip|application/x-7z-compressed|application/x-compressed-tar|application/zip)
                mntdir="$f-archivemount"
                if [ ! -d "$mntdir" ]; then
                    mkdir "$mntdir"
                    ${pkgs.archivemount}/bin/archivemount "$f" "$mntdir"
                    echo "$mntdir" >> "/tmp/__lf_archivemount_$id"
                fi
                mntdir="$(printf '%s' "$mntdir" | sed 's/\\/\\\\/g;s/"/\\"/g')"
                lf -remote "send $id cd \"$mntdir\""
                lf -remote "send $id reload"
                ;;
              *) xdg-open "$fx" > /dev/null 2> /dev/null &;;
          esac
        ''
      );

      z = (
        mkLfCmd
        # bash
        ''
          result="$(zoxide query --exclude $PWD $@ | sed 's/\\/\\\\/g;s/"/\\"/g')"
          lf -remote "send $id cd \"$result\""
        ''
      );

      zi = (
        mkShellCmd
        # bash
        ''
          result="$(zoxide query -i | sed 's/\\/\\\\/g;s/"/\\"/g')"
          lf -remote "send $id cd \"$result\""
        ''
      );

      play = mkAsyncCmd "${pkgs.sox}/bin/play $f";
      stop-playing = (
        mkAsyncCmd
        # bash
        ''
          pkill play
        ''
      );

      mkdir = (
        mkLfCmd
        # bash
        ''
          if [ $# -eq 0  ]; then
            printf "Directory Name: "
            read ans
            mkdir $ans
          else
            mkdir "$@"
          fi
        ''
      );

      new = (
        mkLfCmd
        # bash
        ''
          if [ $# -eq 0  ]; then
            printf "Filename: "
            read ans
            touch $ans
          else
            touch "$@"
          fi
        ''
      );

      select-files = (
        mkAsyncCmd
        # bash
        ''
          get_files() {
              if [ "$lf_hidden" = 'false' ]; then
                  find "$PWD" -mindepth 1 -maxdepth 1 -type f -not -name '.*' -print0
              else
                  find "$PWD" -mindepth 1 -maxdepth 1 -type f -print0
              fi |
              xargs -0 printf ' %q'
          }

          lf -remote "send $id :unselect; toggle $(get_files)"
        ''
      );

      select-dirs = (
        mkAsyncCmd
        # bash
        ''
          get_dirs() {
              if [ "$lf_hidden" = 'false' ]; then
                  find "$PWD" -mindepth 1 -maxdepth 1 -type d -not -name '.*' -print0
              else
                  find "$PWD" -mindepth 1 -maxdepth 1 -type d -print0
              fi |
              xargs -0 printf ' %q'
          }

          lf -remote "send $id :unselect; toggle $(get_dirs)"
        ''
      );

      bulk-rename = (
        mkShellCmd
        # bash
        ''
          printf '%s\n' "$fx" | ${pkgs.moreutils}/bin/vidir -
        ''
      );

      yank-path = (
        mkShellCmd
        # bash
        ''
          printf '%s' "$fx" | paste -sd " " | xargs echo -n | ${config.programs.kitty.package}/bin/kitten clipboard
        ''
      );
    };

    previewer.source = "${pkgs.ctpv}/bin/ctpv";

    extraConfig = ( # bash
      ''
        on-cd
        set cleaner ctpvclear
        &ctpv -s $id
        &ctpvquit $id
      ''
    );

    keybindings = {
      P = "play";
      DD = "delete $fs";
      x = "cut";
      J = ":updir; set dironly true; down; set dironly false; open";
      K = ":updir; set dironly true; up; set dironly false; open";
      o = ":open";

      f = "";
      fs = "fzf-search";
      fj = "fzf-jump";

      gl = "follow-link";

      "<c-d>" = "drag-and-drop";

      # unmap the default rename keybinding
      r = "";
      rB = ":bulk-rename";
      ri = ":rename";
      rI = ":rename; cmd-home";
      rA = ":rename; cmd-end";
      rs = ":rename; cmd-delete-home"; # rename-stem
      rf = ":rename; cmd-end; cmd-delete-home"; # rename-full

      # paths
      y = "";
      yy = "copy";
      yp = "yank-path";

      # toggles
      zp = "toggle-preview";
    };
  };
}
