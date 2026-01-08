{
  description = "The Radicle Website";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {
        inherit system;
      };
    in {
      devShells.default = pkgs.mkShell {
        buildInputs = with pkgs; [
          ruby
          wrangler

          # Ruby native extensions need these to build
          libyaml.dev
          openssl.dev
          zlib.dev
          libffi.dev
        ];
      };
    });
}
