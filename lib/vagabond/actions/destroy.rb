module Vagabond
  module Actions
    module Destroy
      def destroy
        if(lxc.exists?)
          ui.info "#{ui.color('Vagabond:', :bold)} Destroying node: #{ui.color(name, :red)}"
          do_destroy
          ui.info ui.color('  -> DESTROYED', :red)
        else
          ui.error "Node not created: #{name}"
        end
      end

      private

      def do_destroy
        lxc.stop if lxc.running?
        com = "#{Config[:sudo]}lxc-destroy -n #{lxc.name}"
        debug(com)
        cmd = Mixlib::ShellOut.new(com, :live_stream => Config[:debug])
        cmd.run_command
        cmd.error!
        if(cmd.stderr.include?('skipping'))
          ui.info ui.color('  -> Failed to unmount some resources. Forcing manually.', :yellow)
          %w(rootfs ephemeralbind).each do |mnt|
            com = "#{Config[:sudo]}umount /var/lib/lxc/#{lxc.name}/#{mnt}"
            debug(com)
            cmd = Mixlib::ShellOut.new(com, :live_stream => Config[:debug])
            cmd.run_command
            com = "#{Config[:sudo]}lxc-destroy -n #{lxc.name}"
            debug(com)
            cmd = Mixlib::ShellOut.new(com, :live_stream => Config[:debug])
            cmd.run_command
            cmd.error!
            internal_config[mappings_key].delete(name)
          end
          internal_config.save
        end
      end
    end
  end
end
