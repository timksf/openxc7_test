{
    description = "Nix flake for CMOD A7 development with the openXC7 toolchain";

    nixConfig.extra-experimental-features = [ "nix-command" "flakes" ];

    inputs = {
        nixpkgs.url = "github:NixOS/nixpkgs/25.11";
        flake-utils.url = "github:numtide/flake-utils";
        openxc7.url = "github:openXC7/toolchain-nix";
    };

    outputs = { self, flake-utils, nixpkgs, openxc7 } :
        flake-utils.lib.eachSystem ["x86_64-linux"] (system: let
            pkgs = import nixpkgs {
                inherit system;
            };
            openxc7Shell = openxc7.devShell.${system};
            in {
                devShell = with pkgs; pkgs.mkShellNoCC {
                    inputsFrom = [ openxc7Shell ];

                    packages = with pkgs; [
                        xorg.libX11.dev
                        libpng
                        libz
                        imagemagick
                        gcc13
                        cmake
                        ninja
                        gnumake
                        bluespec
                        iverilog
                        vscode-extensions.ms-vscode.cmake-tools
                    ];

                    shellHook = ''
                        ${openxc7Shell.shellHook}
                    '';
                };
            }
        );
}