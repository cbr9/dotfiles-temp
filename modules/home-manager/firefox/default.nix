{
  pkgs,
  config,
  nixosConfig,
  lib,
  ...
}: {
  imports = [
    ./bookmarks.nix
    ./search.nix
    ./extensions.nix
    ./settings.nix
  ];

  home.sessionVariables = {
    MOZ_USE_XINPUT2 = "1";
  };
  home.packages = lib.mkIf config.programs.firefox.enable [pkgs.speechd];
  programs.firefox = {
    enable = nixosConfig != {};
    package = pkgs.firefox.override {
      cfg = {
        speechSynthesisSupport = true;
        enablePlasmaBrowserIntegration = true;
        enableGnomeExtensions = nixosConfig.services.xserver.desktopManager.gnome.enable;
        enableTridactylNative = builtins.elem nixosConfig.nur.repos.rycee.firefox-addons.tridactyl config.programs.firefox.profiles.default.extensions;
      };
      extraPolicies = import ./policies.nix {inherit config;};
    };
    profiles.default = {
      isDefault = true;
    };
  };
}
