{ stdenv, fetchgit, fetchurl, ruby, rubyLibs, buildEnv, libiconv, libxslt,
libxml2, pkgconfig, which, icu, libffi, mysql, postgresql }:

with stdenv.lib;

let 
gems = buildEnv {
  name = "rubygems";
  ignoreCollisions = true;
  paths = [
    ruby
    (overrideDerivation rubyLibs.bundler (oldAttrs: { dontPatchShebangs = 1; }))
  ];
  };
in 
  stdenv.mkDerivation rec {
  name = "gitlab-${version}";
  version = "v7.1.0";

  src = fetchgit {
    url = "https://github.com/gitlabhq/gitlabhq.git";
    rev = "refs/tags/${version}";
    sha256 = "1pbbnvf3hlnm7f3rh5wd180mp4iddhial9n8f41lgm603ssv3plr";
  };

  gemspec = map (gem: fetchurl { url=gem.url; sha256=gem.hash; }) (import ./Gemspec.nix);

  GEM_PATH="${gems}/lib/ruby/gems/2.0";

  buildInputs = [ gems libiconv libxslt libxml2 pkgconfig which icu libffi mysql postgresql ];

  installPhase = ''
    cp -R . $out && cd $out
    echo Copied gitlab source to $out
    export HOME=$(pwd)
    mkdir -p vendor/cache
    ${concatStrings (map (gem: '' ln -s ${gem} vendor/cache/${gem.name} '') gemspec)}

    bundle config build.nokogiri --use-system-libraries --with-iconv-dir=${libiconv} --with-xslt-dir=${libxslt} --with-xml2-dir=${libxml2} --with-pkg-config
    bundle install --verbose --local --deployment --without development test
    ln -s /etc/gitlab/config.yml ./config/config.yml
    ln -s /etc/gitlab/database.yml ./config/database.yml
    ln -s /etc/gitlab/unicorn.rb ./config/unicorn.rb
  '';
}
