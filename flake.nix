{
  description = "Development shell for the Zola blog";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = {
    self,
    nixpkgs,
  }: let
    supportedSystems = [
      "aarch64-darwin"
      "aarch64-linux"
      "x86_64-darwin"
      "x86_64-linux"
    ];

    forAllSystems = function:
      nixpkgs.lib.genAttrs supportedSystems (system:
        function nixpkgs.legacyPackages.${system});
  in {
    devShells = forAllSystems (pkgs: {
      default = pkgs.mkShell {
        packages = with pkgs; [
          just
          pandoc
          quickjs-ng
          zola
        ];

        shellHook = ''
          if [ -f .env ]; then
            set -a
            . ./.env
            set +a
          fi
        '';
      };
    });
  };
}
