{ cabal, attoparsec, deepseq, hspec, mtl, QuickCheck, text }:

cabal.mkDerivation (self: {
  pname = "bencoding";
  version = "0.4.3.0";
  sha256 = "0f6d3g88y7i4s5wa53771n0fbkbs4na8vpy51wk21b563smdcpcc";
  buildDepends = [ attoparsec deepseq mtl text ];
  testDepends = [ attoparsec hspec QuickCheck ];
  meta = {
    homepage = "https://github.com/cobit/bencoding";
    description = "A library for encoding and decoding of BEncode data";
    license = self.stdenv.lib.licenses.bsd3;
    platforms = self.ghc.meta.platforms;
  };
})
