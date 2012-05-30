require 'pkgr/base_app'

module Pkgr
  class GenericApp < BaseApp

    # We don't have a binary in a generic app
    def setup_binary
    end

    def build_debian_package(host, port = 22)
      puts "Building debian package on '#{host}'..."
      Dir.chdir(root) do
        Pkgr.mkdir("pkg")
        archive = "#{name}-#{version}"
        cmd = %Q{
          git archive #{git_ref} --prefix=#{archive}/ | ssh #{host} -p #{port} 'cat - > /tmp/#{archive}.tar &&
            set -x && rm -rf /tmp/#{archive} &&
            cd /tmp && tar xf #{archive}.tar && cd #{archive} &&
            #{debian_steps.join(" &&\n")}'
        }
        sh cmd
        # Fetch the .deb, and put it in the `pkg` directory
        sh "scp -P #{port} #{host}:/tmp/#{name}_#{version}* pkg/"
      end
    end

    def debian_steps
      target_vendor = "vendor/bundle/ruby/1.9.1"
      [
        "sudo apt-get install #{debian_runtime_dependencies(true).join(" ")} -y",
        "dpkg-buildpackage -us -uc -d"
      ]
    end

  end
end
