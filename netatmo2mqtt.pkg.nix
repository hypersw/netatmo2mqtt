{stdenv, lib, python38, fetchFromGitHub}:
with stdenv.lib;
python38.pkgs.buildPythonApplication rec 
{
  pname = "netatmo2mqtt";
  version = "1.0";

  src = fetchFromGitHub 
  {
    owner = "seblucas";
    repo = "netatmo2mqtt";
    rev = "36969844075247dadc3b042d1eb0ced9df68a771";
    sha256 = "1wjg7b1mcjhgqdy937pkscl5sizcdjxp5pgrd40gin29jpha24y9";
  };

  propagatedBuildInputs = 
  with python38.pkgs; 
  [
    requests 
    paho-mqtt
  ];
  
  format = "other";

#  buildPhase = ''
#  python -O -m compileall .
#  '';
#
  installPhase = ''
    mkdir "$out"
    cp -r *.py "$out/"
    echo "Files in outdir:"
    ls -la "$out"
  '';
    #install -Dm755 netatmo2MQTT "$out/xx"

  doCheck = false; # no tests implemented

  meta = with lib; 
  {
    description = "Get the measures from your NetAtmo thermostat and send it to your MQTT broker";
    homepage = "https://github.com/seblucas/netatmo2mqtt";
    license = licenses.gpl3;    
  };
}
