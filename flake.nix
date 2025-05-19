{
  description = "Tapis documentation";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        python = pkgs.python311;
        docsPython = python.withPackages (ps: [
          ps.sphinx
          ps.sphinx-autobuild
          ps.sphinx_rtd_theme
          ps.sphinx-tabs
          ps.docutils
          ps.setuptools
        ]);
        commonPackages = [ docsPython pkgs.rsync pkgs.gnumake ];
      in {
        devShells = {
          default = pkgs.mkShell {
            packages = commonPackages;
            shellHook = ''
              echo "Entering Tapis documentation nix shell..."
              echo "Python version: $("${docsPython}/bin/python" --version)"
              echo "Nix version: $(nix --version)"
              echo ""
              echo "Available nix commands:"
              echo "=========================="
              echo "  - nix develop -i: --ignore-environment to isolate nix shell from user env"
              echo "  - nix develop .#live: runs 'make livehtml'"
              echo "  - nix develop .#help: runs 'make help' to display sphinx options, run 'make <cmd>' from help"
              echo "  - nix develop .#server: Build and serve docs with python, for no particular reason"
              echo "  - nix develop .#status: Show installed Python packages"
              echo "  - nix build: Build the docs and output to build/html"
              echo ""
              echo "Available make commands:"
              echo "=========================="
              echo "  - make html: Build the docs"
              echo "  - make livehtml: Build the docs and start a live preview server"
              echo "  - make clean: Clean the build directory"
              echo "  - make help: View all Sphinx options which make will passthrough"
            '';
          };
          
          live = pkgs.mkShell {
            packages = commonPackages;
            shellHook = ''
              echo "Entering Tapis docs nix shell..."
              echo "Starting live preview..."
              echo "  - use output url to view docs"
              echo "  - use Ctrl+C to stop the server"
              echo "=========================="
              exec make livehtml
            '';
          };
          help = pkgs.mkShell {
            packages = commonPackages;
            shellHook = ''
              echo "Entering Tapis docs nix shell..."
              echo "Available make commands:"
              echo "========================="
              make help
            '';
          };

          status = pkgs.mkShell {
            packages = commonPackages;
            shellHook = ''
              echo "Entering Tapis docs nix shell..."
              echo "Available Python packages:"
              echo "=========================="
              ${docsPython}/bin/python -c "
          from importlib.metadata import distributions
          installed_packages = list(distributions())
          installed_packages.sort(key=lambda x: x.metadata['Name'].lower())
          for package in installed_packages:
              print(f'{package.metadata[\"Name\"]} {package.version}')
          "
            '';
          };
          
          server = pkgs.mkShell {
            packages = commonPackages ++ [ python.pkgs.httpserver ];
            shellHook = ''
              echo "Entering Tapis docs nix shell..."
              echo "Building docs and starting HTTP server..."
              echo "  - use output url to view docs"
              echo "  - use Ctrl+C to stop the server"
              echo "=========================="
              make html
              echo "Serving docs via python at: http://localhost:8000/"
              cd build/html && python -m http.server
            '';
          };
        };
        
        packages = {
          default = pkgs.stdenv.mkDerivation {
            # builds to ./result
            name = "tapis-docs";
            src = ./.;
            buildInputs = commonPackages;
            buildPhase = ''
              make html
            '';
            installPhase = ''
              mkdir -p $out
              cp -r build/html $out/
            '';
          };
        };
      }
    );
}

