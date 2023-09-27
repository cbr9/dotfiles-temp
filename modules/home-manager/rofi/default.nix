{
  pkgs,
  config,
  ...
}:
with pkgs; {
  stylix.targets.rofi.enable = false;
  programs.rofi = {
    enable = true;
    plugins = [rofi-emoji rofi-calc rofi-pulse-select rofi-bluetooth];
    terminal = config.home.sessionVariables.TERMINAL;
    cycle = true;
    theme = "gruvbox-dark-hard";
    extraConfig = {
      modes = "calc,emoji";
      dpi = 120;
    };
  };
}
