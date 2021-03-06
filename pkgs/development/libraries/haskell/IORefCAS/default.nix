# This file was auto-generated by cabal2nix. Please do NOT edit manually!

{ cabal, bitsAtomic, HUnit, QuickCheck, time }:

cabal.mkDerivation (self: {
  pname = "IORefCAS";
  version = "0.2.0.1";
  sha256 = "06vfck59x30mqa9h2ljd4r2cx1ks91b9gwcr928brp7filsq9fdb";
  buildDepends = [ bitsAtomic ];
  testDepends = [ bitsAtomic HUnit QuickCheck time ];
  meta = {
    homepage = "https://github.com/rrnewton/haskell-lockfree-queue/wiki";
    description = "Atomic compare and swap for IORefs and STRefs";
    license = self.stdenv.lib.licenses.bsd3;
    platforms = self.ghc.meta.platforms;
    maintainers = [ self.stdenv.lib.maintainers.andres ];
  };
})
