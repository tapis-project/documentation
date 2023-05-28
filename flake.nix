{
  description = "Tapis documentation";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-22.11";
    flake-utils.url = "github:numtide/flake-utils";
    shell-utils.url = "github:waltermoreira/shell-utils";
  };

  outputs =
    { self
    , nixpkgs
    , flake-utils
    , shell-utils
    }:

      with flake-utils.lib; eachDefaultSystem
        (system:
        let
          pkgs = import nixpkgs { inherit system; };
          generatedPythonPkgs = import ./python-packages.nix {
            inherit pkgs;
            inherit (pkgs) fetchurl fetchgit fetchhg;
          };
          pythonPkgs = with pkgs.lib;
            fix (extends generatedPythonPkgs (self: myPython.pkgs));
          shell = shell-utils.myShell.${system};
          myPython = pkgs.python310;
          docsPython = (myPython.withPackages (
            ps: with pythonPkgs; [
              sphinx
              sphinx-autobuild
              sphinx-rtd-theme
              sphinx-tabs
              docutils
            ]
          )).override (args: { ignoreCollisions = true; });
          site = pkgs.stdenv.mkDerivation {
            name = "site";
            src = ./.;
            buildInputs = [
              docsPython
              pkgs.rsync
              pkgs.gnumake
            ];
            buildPhase = ''
              make html
            '';
            installPhase = ''
              mkdir -p $out/html
              rsync -a build/html $out
            '';
          };
        in
        {
          packages.default = site;
          devShells.default = shell {
            packages = [ ] ++ site.buildInputs;
          };
          devShells.live = pkgs.mkShell {
            packages = [ ] ++ site.buildInputs;
            shellHook = ''
              exec sh -c "make livehtml"
            '';
          };
        });
}
