{pkgs ? import <nixpkgs> {}}:
pkgs.mkShell {
  buildInputs = [
    pkgs.just
    pkgs.pandoc
    pkgs.quickjs
    pkgs.rsync
    pkgs.zola
  ];

  shellHook = ''
  '';
}
