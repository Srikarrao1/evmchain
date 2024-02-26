{ pkgs
, config
, anryton ? (import ../. { inherit pkgs; })
}: rec {
  start-anryton = pkgs.writeShellScriptBin "start-anryton" ''
    # rely on environment to provide anrytond
    export PATH=${pkgs.test-env}/bin:$PATH
    ${../scripts/start-anryton.sh} ${config.anryton-config} ${config.dotenv} $@
  '';
  start-geth = pkgs.writeShellScriptBin "start-geth" ''
    export PATH=${pkgs.test-env}/bin:${pkgs.go-ethereum}/bin:$PATH
    source ${config.dotenv}
    ${../scripts/start-geth.sh} ${config.geth-genesis} $@
  '';
  start-scripts = pkgs.symlinkJoin {
    name = "start-scripts";
    paths = [ start-anryton start-geth ];
  };
}
