# This file was auto-generated by cabal2nix. Please do NOT edit manually!

{ cabal, hspec, HUnit, mtl, syb }:

cabal.mkDerivation (self: {
  pname = "th-desugar";
  version = "1.4.2";
  sha256 = "16l0khjx2wppnm9spp6mg659m95hxjkzfv3pjw5ays3z6clhx8b9";
  buildDepends = [ mtl syb ];
  testDepends = [ hspec HUnit mtl syb ];
  doCheck = false;
  meta = {
    homepage = "http://www.cis.upenn.edu/~eir/packages/th-desugar";
    description = "Functions to desugar Template Haskell";
    license = self.stdenv.lib.licenses.bsd3;
    platforms = self.ghc.meta.platforms;
    maintainers = [ self.stdenv.lib.maintainers.ocharles ];
  };
})
