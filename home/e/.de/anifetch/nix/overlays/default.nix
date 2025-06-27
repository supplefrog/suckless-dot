{
  anifetch = final: _prev: {
    anifetch = import ../packages/anifetch.nix final.pkgs;
  };
}
