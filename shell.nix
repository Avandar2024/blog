{pkgs ? import <nixpkgs> {}}:
pkgs.mkShell {
  buildInputs = [
    pkgs.just
    pkgs.nodejs
    pkgs.pandoc
    pkgs.rsync
    pkgs.zola
  ];

  shellHook = ''
  '';
}
