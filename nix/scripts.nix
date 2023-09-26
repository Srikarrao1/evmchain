{ pkgs
, config
, shido ? (import ../. { inherit pkgs; })
}: rec {
  start-shido = pkgs.writeShellScriptBin "start-shido" ''
    # rely on environment to provide shidod
    export PATH=${pkgs.test-env}/bin:$PATH
    ${../scripts/start-shido.sh} ${config.shido-config} ${config.dotenv} $@
  '';
  start-geth = pkgs.writeShellScriptBin "start-geth" ''
    export PATH=${pkgs.test-env}/bin:${pkgs.go-ethereum}/bin:$PATH
    source ${config.dotenv}
    ${../scripts/start-geth.sh} ${config.geth-genesis} $@
  '';
  start-scripts = pkgs.symlinkJoin {
    name = "start-scripts";
    paths = [ start-shido start-geth ];
  };
}
