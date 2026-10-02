{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgs-esp-dev = {
      # Pull directly from dvdvgt's branch with all the v6.0.1 fixes
      url = "github:dvdvgt/nixpkgs-esp-dev/update-v6.0.1";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-esp-dev,
    }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        overlays = [
          # Handle the dropped python310 on bleeding-edge nixpkgs
          (final: prev: {
            python310 = prev.python311;
            python310Packages = prev.python311Packages;
          })
          (import "${nixpkgs-esp-dev}/overlay.nix")
        ];
        config.permittedInsecurePackages = [
          "python3.14-ecdsa-0.19.2"
        ];
      };

      # v6 PR consolidates targets into esp-idf-xtensa / esp-idf-full
      idf = pkgs.esp-idf-xtensa.override (final: {
        toolsToInclude = builtins.filter (t: t != "xtensa-esp-elf-gdb") (
          final.toolsToInclude ++ [ "esp-clang" ]
        );
      });
    in
    {
      devShells.${system}.default = pkgs.mkShell {
        buildInputs = [
          idf
        ];

        shellHook = ''
          export CLANGD_QUERY_DRIVER=`which xtensa-esp32s3-elf-gcc`
        '';
      };
    };
}
