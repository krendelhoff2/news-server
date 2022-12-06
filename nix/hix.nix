{ pkgs, ... }:
{
  name = "news-server";

  compiler-nix-name = "ghc8107";

  shell = {
    tools = {
      cabal = "latest";
      hpack = {};
      haskell-language-server = {};
    };
    buildInputs = with pkgs; [
      haskellPackages.implicit-hie
      postgresql
    ];
  };
}
