let
  sources = import ./nix/sources.nix;
  minNixVer = "2.4";
in { pkgs ? import sources.nixpkgs { } }:

assert pkgs.lib.assertMsg
  (builtins.compareVersions minNixVer pkgs.nix.version != 1)
  "The project doesn't support Nix of version ${pkgs.nix.version}. The minimum required version is ${minNixVer}.";

let
  naersk = pkgs.callPackage sources.naersk { };
  gitignoreSource = (pkgs.callPackage sources.gitignore { }).gitignoreSource;
  blake3-src = sources.BLAKE3;

  ESSENTIALS = with pkgs;
    lib.makeBinPath [ bashInteractive coreutils nix gitMinimal gnutar gzip ];
  BASH = "${pkgs.bashInteractive}/bin/bash";
  NIX_BIN = "${pkgs.nix}/bin";
  IN_NIX = true;

  # The main cached-nix-shell package. It's subject for override (see below) of the 
  # underlying derivation attributes so the build works correctly.
  package = naersk.buildPackage {
    root = gitignoreSource ./.;
    buildInputs = with pkgs; [ openssl nix ronn ];
  };
  # Final overrides.
  package' = package.overrideAttrs (_: {
    inherit ESSENTIALS BASH NIX_BIN IN_NIX;
    CNS_GIT_COMMIT = if builtins.pathExists ./.git then
      pkgs.lib.commitIdFromGitRepo ./.git
    else
      "next";
    BLAKE3_CSRC = "${blake3-src}/c";
    postBuild = ''
      make -f nix/Makefile post-build
    '';
    postInstall = ''
      make -f nix/Makefile post-install
    '';
  });
in package'
