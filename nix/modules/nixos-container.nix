{ self, config, pkgs, ... }:
{
  boot.isContainer = true;

  system = {
    configurationRevision = pkgs.lib.mkIf (self ? rev) self.rev;
    stateVersion = "22.11";
  };

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ config.services.news-server.config.port ];
  };

  services.news-server.enable = true;
}
