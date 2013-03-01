# ROOT=. rake -I lib -f lib/pkgr/pkgr.rake pkgr:setup

require 'pkgr'
require 'fileutils'

def pkgr_init
  @root = ENV.fetch('ROOT') { defined?(Rails) ? Rails.root : PROJECT_ROOT }
  @config = ENV.fetch('CONFIG') { File.join(@root, "config/pkgr.yml") }
  if File.exist?(@config)
    @app = Pkgr.create_app(@root, @config)
    @app.valid? || fail("There is an issue with the app you're trying to package: #{@app.errors.join(", ")}")
  end
end

namespace :pkgr do

  desc "Setup the required files for pkgr"
  task :setup do
    pkgr_init
    Pkgr.setup(@root)
  end

  desc "Get the current package version"
  task :version do
    pkgr_init
    puts YAML.load_file(@config)["version"]
  end

  desc "Get the name of the package"
  task :name do
    pkgr_init
    puts YAML.load_file(@config)["name"]
  end

  task :generate do
    pkgr_init
    @app.generate_required_files
  end

  namespace :bump do
    %w{patch minor major custom}.each do |version|
      desc "Increments the #{version} version. If using :custom, then you can pass a specific VERSION environment variable."
      pkgr_init
      task version.to_sym do
        @app.bump!(version.to_sym, ENV['VERSION'])
      end
    end
  end

  namespace :build do
    desc "Builds the debian package"
    task :deb do
      pkgr_init
      build_host, build_port = ENV.fetch('HOST') { 'localhost' }.split(":")
      apt_user = ENV.fetch('USER') {''}
      @app.build_debian_package(build_host, build_port || 22, apt_user)
    end
  end
    
  namespace :release do
    desc "Release the latest package on a custom APT repository"
    task :deb do
      pkgr_init
      apt_host, apt_port = ENV.fetch('HOST') { 'localhost' }.split(":")      
     @app.release_debian_package(apt_host, apt_port || 22)
    end
  end
end
