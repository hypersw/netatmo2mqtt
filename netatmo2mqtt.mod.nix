{ config, lib, pkgs, netatmo2mqtt, ... }:

with lib;

let

  cfg = config.services.netatmo2mqtt;

in

{

  ###### interface

  options = 
  {
    services.netatmo2mqtt = 
    {
      enable = mkOption 
      {
        default = false;
        description = "Whether to enable the bridge.";
      };
    };
  };


  ###### implementation

  config = 
  let
      username = "netatmo2mqtt";
      pkgself = pkgs.callPackage ./netatmo2mqtt.pkg.nix {};
  in 
  mkIf cfg.enable
  {
    environment.systemPackages = [pkgself];

    users.users."${username}".description = "Netatmo 2 MQTT Bridge User";

    systemd.services.netatmo2mqtt = 
    let
      pathExe = "${pkgself.out}/netatmo2MQTT.py";
      dirlocalname = "netatmo2mqtt";      
    in
    {
      description = "Netatmo 2 MQTT Bridge";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];   ## TODO: is it?
      
      serviceConfig = 
      {
        #Type = "exec"; # TODO: why cannot set exec?
        ExecStart  = "${pathExe} -c '<CLIENT_ID>' -a '<CLIENT_SECRET>' -r '<REFRESH_TOKEN>'";
        
        Restart = "always";
        RestartSec = "10";
        TimeoutStopSec = "30";  # Assume might be executing shutdown scripts
        
        # Dirs for storing various data, created by systemd for us
        RuntimeDirectory = dirlocalname;  # /run/ # RUNTIME_DIRECTORY
        StateDirectory = dirlocalname;  # /var/lib/ # STATE_DIRECTORY
        CacheDirectory = dirlocalname;  # /var/cache/ # CACHE_DIRECTORY
        LogsDirectory =	dirlocalname;  # /var/log/ # LOGS_DIRECTORY
        
        User = username;
      };
    };
  };
}