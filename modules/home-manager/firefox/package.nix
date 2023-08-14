{
  pkgs,
  nixosConfig,
  ...
}: {
  programs.firefox.package = pkgs.firefox.override {
    cfg = {
      enableGnomeExtensions = nixosConfig.services.xserver.desktopManager.gnome.enable;
    };
    extraPolicies = import ./policies.nix;
  };
}