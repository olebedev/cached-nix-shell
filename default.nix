let sources = import ./nix/sources.nix;
in { pkgs ? import sources.nixpkgs { } }:

let
  naersk = pkgs.callPackage sources.naersk { };
  gitignoreSource = (pkgs.callPackage sources.gitignore { }).gitignoreSource;
  blake3-src = sources.BLAKE3;
in
(naersk.buildPackage {
  root = gitignoreSource ./.;
  buildInputs = [ pkgs.openssl pkgs.nix pkgs.ronn ];
}).overrideAttrs (attrs: {
  CNS_GIT_COMMIT =
    if builtins.pathExists ./.git then
      pkgs.lib.commitIdFromGitRepo ./.git
    else
      "next";
  BLAKE3_CSRC = "${blake3-src}/c";
  postBuild = "make -f nix/Makefile post-build";
  postInstall = "make -f nix/Makefile post-install";
})
