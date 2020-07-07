{ config, lib, pkgs, netatmo2mqtt, python38, ... }:

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
      enable = mkEnableOption "the Netatmo into MQTT bridge";
      
      verbose = mkOption
      {
        type = types.bool;
        default = false;
        description = "Enable debug messages.";
      };      
      
      netatmo = 
      {
          clientId = mkOption
          {
            type = types.str;
            description = "The client_id which you get when you register an application on Netatmo website (https://dev.netatmo.com/myaccount/createanapp).";
          };
          
          clientSecret = mkOption
          {
            type = types.str;
            description = "The cleartext client_secret which you get when you register an application on Netatmo website (https://dev.netatmo.com/myaccount/createanapp).";
          };
          
          refreshToken = mkOption
          {
            type = types.str;
            description = "TODO.";
          };
      };
      
      mqtt = 
      {
        hostname = mkOption
        {
          type = types.str;
          description = "Specify the MQTT host to connect to.";
        };
        
        topic = mkOption
        {
          type = types.str;
          default = "sensor/mainroom";
          description = "The MQTT topic on which to publish the message (if it was a success).";
        };
        
        topicSetpoint = mkOption
        {
          type = types.str;
          default = "sensor/setpoint";
          description = "The MQTT topic on which to publish the message with the current setpoint temperature (if it was a success).";
        };
        
        topicError = mkOption
        {
          type = types.str;
          default = "error/sensor/mainroom";
          description = "The MQTT topic on which to publish the message (if it wasn't a success).";
        }; 
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
      pathInterpreter = "${pkgs.python38.withPackages(ps: [ ps.requests ps.paho-mqtt ])}/bin/python3";
      pathPy = "${pkgself.out}/netatmo2MQTT.py";
      dirlocalname = "netatmo2mqtt";      
    in
    {
      description = "Netatmo 2 MQTT Bridge";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];   ## TODO: is it?
      
      serviceConfig = 
      {
        #Type = "exec"; # TODO: why cannot set exec?
        ExecStart  = "${pathInterpreter} ${pathPy} --client-id '${cfg.netatmo.clientId}' --client-secret '${cfg.netatmo.clientSecret}' --refresh-token '${cfg.netatmo.refreshToken}' --mqtt-host '${cfg.mqtt.hostname}' --topic '${cfg.mqtt.topic}' --topic-setpoint '${cfg.mqtt.topicSetpoint}' --topic-error '${cfg.mqtt.topicError}' ${if cfg.verbose then "--verbose" else ""}";
        
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
