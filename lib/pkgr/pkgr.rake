# ROOT=. rake -I lib -f lib/pkgr/pkgr.rake pkgr:setup

require 'pkgr'
require 'fileutils'

ROOT = ENV.fetch('ROOT') { defined?(Rails) ? Rails.root : PROJECT_ROOT }
CONFIG = ENV.fetch('CONFIG') { File.join(ROOT, "config/pkgr.yml") }
if File.exist?(CONFIG)
  APP = Pkgr.create_app(ROOT, CONFIG)
  APP.valid? || fail("There is an issue with the app you're trying to package: #{APP.errors.join(", ")}")
end

namespace :pkgr do

  desc "Setup the required files for pkgr"
  task :setup do
    Pkgr.setup(ROOT)
  end

  desc "Get the current package version"
  task :version do
    puts YAML.load_file(CONFIG)["version"]
  end

  desc "Get the name of the package"
  task :name do
    puts YAML.load_file(CONFIG)["name"]
  end

  if defined?(APP)
    task :generate do
      APP.generate_required_files
    end

    namespace :bump do
      %w{patch minor major custom}.each do |version|
        desc "Increments the #{version} version. If using :custom, then you can pass a specific VERSION environment variable."
        task version.to_sym do
          APP.bump!(version.to_sym, ENV['VERSION'])
        end
      end
    end

    namespace :build do
      desc "Builds the debian package"
      task :deb do
        build_host, build_port = ENV.fetch('HOST') { 'localhost' }.split(":")
        APP.build_debian_package(build_host, build_port || 22)
      end
    end
    
    namespace :release do
      desc "Release the latest package on a custom APT repository"
      task :deb do
        apt_host, apt_port = ENV.fetch('HOST') { 'localhost' }.split(":")
        apt_user = ENV.fetch('USER') {''}
        APP.release_debian_package(apt_host, apt_port || 22, apt_user)
      end
    end
  end
end
