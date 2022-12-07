{ config, lib, pkgs, ... }:
with lib; let
  cfg = config.services.news-server;
in {
  options.services.news-server = {
    enable = mkEnableOption "news-server service";
    config = mkOption {
      description = "news-server configuration options";
      type = types.attrs;
      default = {
        port = 7980;

        logging = {
          enable = true;
          level = "INFO";
        };

        db = {
          hostName = "localhost";
          port = 5432;
          user = "nixcloud";
          dbName = "nixcloud";
          dbPassword = "nixcloud";
          pool = {
            size = 10;
            timeout = 5;
          };
        };
      };
    };
  };

  config =
  let
    inherit (cfg) config;
  in mkIf cfg.enable {
    services.postgresql = {
      enable = true;
      package = pkgs.postgresql;
      enableTCPIP = true;
      port = config.db.port;
      authentication = pkgs.lib.mkOverride 10 ''
        local all all trust
        host all all 127.0.0.1/32 trust
        host all all ::1/128 trust
      '';
      initialScript = pkgs.writeText "backend-initScript" ''
        CREATE ROLE ${config.db.user} WITH LOGIN PASSWORD '${config.db.dbPassword}' CREATEDB;
        CREATE DATABASE ${config.db.dbName};
        GRANT ALL PRIVILEGES ON DATABASE ${config.db.dbName} TO ${config.db.user};
      '';
    };
    systemd.services.news-server =
    let
      configFileJSON = pkgs.writeTextFile {
        name = "config.json";
        text = builtins.toJSON {
          inherit (config) port;
          doLogging = config.logging.enable;
          logLevel = config.logging.level;
          dbConfig = { inherit (config.db) hostName port user dbName dbPassword; };
          dbPoolSettings = { inherit (config.db.pool) size timeout; };
        };
      };
      configFile = pkgs.runCommand "config.yaml" {
        src = configFileJSON;
        buildInputs = [ pkgs.yq ];
      } "yq -y . $src | tee $out";
    in {
      enable = true;
      wantedBy = [ "multi-user.target" ];
      after = [ "postgresql.service" ];
      serviceConfig.ExecStart = "${pkgs."server:exe:server"}/bin/server -c ${configFile}";
    };
  };
}
