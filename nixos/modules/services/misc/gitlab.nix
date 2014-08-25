{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.services.gitlab;

  ruby = pkgs.ruby2;
  rubyLibs = pkgs.ruby2Libs;

  gemspec = map (gem: pkgs.fetchurl { url=gem.url; sha256=gem.hash; })
    (import <nixpkgs/pkgs/applications/version-management/gitlab/Gemfile.nix>);

  gitlab = with pkgs; stdenv.mkDerivation rec {
    version = "v7.1.0";
    name = "gitlab-${version}";
    src = fetchurl {
      url = "https://github.com/gitlabhq/gitlabhq/archive/7-1-stable.zip";
      sha256 = "0lfcpwvijkx7by89x51z9kycgrzapl8vr8x3x82dkj099m51k89v";
    };

  buildInputs = [  ruby rubyLibs.bundler libiconv libxslt libxml2 pkgconfig
  which icu libffi  postgresql unzip];

    installPhase = ''
      cp -R . $out
      cd $out
      export HOME=$(pwd)

      mkdir -p vendor/cache

      ${concatStrings (map (gem: "ln -s ${gem} vendor/cache/${gem.name};") gemspec)}

      cat > config/database.yml <<EOF
      production:
        adapter: postgresql
        database: gitlabhq_production
        host: 127.0.0.1
        username: gitlab
        password: 12345
        encoding: utf8
      EOF

      cat > config/gitlab.yml <<EOF
      production: &base
        gitlab:
          host: localhost
          port: 80
          https: false
          email_from: example@example.com
          default_projects_limit: 10

          default_projects_features:
            issues: true
            merge_requests: true
            wiki: true
            snippets: false
            visibility_level: "private"  # can be "private" | "internal" | "public"
          # repository_downloads_path: tmp/repositories

         satellites:
           path: ${cfg.stateDir}/gitlab-satellites/
        
         backup:
           path: "tmp/backups"   # Relative paths are relative to Rails.root (default: tmp)
       
         gitlab_shell:
           path: ${cfg.stateDir}/gitlab-shell/

         # REPOS_PATH MUST NOT BE A SYMLINK!!!
         repos_path: ${cfg.stateDir}/repositories/
         hooks_path: ${cfg.stateDir}/gitlab-shell/hooks/
                      
         upload_pack: true
         receive_pack: true

         git:
           bin_path: /usr/bin/git
           max_size: 20971520 # 20.megabytes
           timeout: 10
      EOF   
         
      cat > config/unicorn.rb <<EOF
      worker_processes 2
      working_directory "${cfg.stateDir}/gitlab" # available in 0.94.0+
      listen "${cfg.stateDir}/gitlab/tmp/sockets/gitlab.socket", :backlog => 64
      listen "127.0.0.1:8080", :tcp_nopush => true
      timeout 30
      pid "${cfg.stateDir}/gitlab/tmp/pids/unicorn.pid"
      stderr_path "${cfg.stateDir}/gitlab/log/unicorn.stderr.log"
      stdout_path "${cfg.stateDir}/gitlab/log/unicorn.stdout.log"
      preload_app true
      GC.respond_to?(:copy_on_write_friendly=) and
        GC.copy_on_write_friendly = true
      check_client_connection false

      before_fork do |server, worker|
        defined?(ActiveRecord::Base) and
          ActiveRecord::Base.connection.disconnect!

        old_pid = "#{server.config[:pid]}.oldbin"
        if old_pid != server.pid
          begin
            sig = (worker.nr + 1) >=
      worker_processes ? :QUIT : :TTOU
            Process.kill(sig,
      read(old_pid).to_i)
          rescue Errno::ENOENT, Errno::ESRCH
          end
        end
      end

      after_fork do |server, worker|
        defined?(ActiveRecord::Base) and ActiveRecord::Base.establish_connection
      end
      EOF

      bundle config build.nokogiri --use-system-libraries --with-iconv-dir=${libiconv} --with-xslt-dir=${libxslt} --with-xml2-dir=${libxml2} --with-pkg-config --with-pg-config=${postgresql}/bin/pg_config
      bundle install --verbose --local --deployment --without development test mysql aws
    '';
  };

in {

  options = {
    services.gitlab = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Enable the redmine service.
        '';
      };

      stateDir = mkOption {
        type = types.str;
        default = "/var/gitlab";
        description = "The state directory, logs and plugins are stored here";
      };

    };
  };

  config = mkIf cfg.enable {

    users.extraUsers = [
      { name = "gitlab";
        description = "Gitlab daemon";
        group = "gitlab";
        uid = config.ids.uids.gitlab;
      } ];

    users.extraGroups = [
      { name = "gitlab";
        gid = config.ids.gids.gitlab;
      } ];

    systemd.services.gitlab = {
      after = [ "redis.service, syslog.service network.target postgresql.service" ];
      wantedBy = [ "multi-user.target" ];
      environment.RAILS_ENV = "production";
      environment.GEM_HOME = "${gitlab}/vendor/bundle/ruby/${ruby.majorVersion}.${ruby.minorVersion}";
      environment.HOME = "${gitlab}";
      environment.REDMINE_LANG = "en";
      environment.GEM_PATH = "${rubyLibs.bundler}/lib/ruby/gems/2.0";
      path = [ gitlab ];
      preStart = ''

        for i in db files log tmp public/plugin_assets; do
          mkdir -p ${cfg.stateDir}/$i
        done
        touch ${cfg.stateDir}/db/schema.rb

        chown -R gitlab:gitlab ${cfg.stateDir}
        chmod -R 755 ${cfg.stateDir}

        #cd ${gitlab}
        #${ruby}/bin/rake db:migrate
        #${ruby}/bin/rake gitlab:load_default_data
      '';

      serviceConfig = {
        PermissionsStartOnly = true; # preStart must be run as root
        Type = "simple";
        User = "gitlab";
        Group = "gitlab";
        TimeoutSec = "300";
        WorkingDirectory = "${gitlab}";
        ExecStart="${ruby}/bin/ruby ${gitlab}/script/rails server webrick -e production";
      };
    };
  };
}
