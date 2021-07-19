require 'chef/resource'

use_inline_resources

def whyrun_supported?
  true
end

action :create do
  if platform_family?('aix')
    ppsize = {}
    pps = {}
    vgs = shell_out('lsvg -o').stdout.chomp
    vgs.split.each do |vg|
      ppsize[vg] = shell_out("lsvg #{vg} | grep 'PP SIZE' | awk '{print $6}'").stdout.chomp.to_i
    end

    lsvg = Mixlib::ShellOut.new('lsvg ' + @vgname)
    lsvg.run_command
    if lsvg.error?
      Chef::Log.error('the volume group ' + @vgname + ' does not exist')
      Chef::Log.error("\n" + lsvg.stderr)
      raise
    end

    pps[@lvname] = @size / ppsize[@vgname]
    pps[@lvname] += 1 if ppsize[@vgname] * pps[@lvname] < @size

    cmds = { 'lv' => "mklv -y #{@lvname} -t #{@fstype} -bn #{@vgname} #{pps[@lvname]}",
             'fs' => "crfs -v #{@fstype} -d #{@lvname} -m #{@fsname} -A yes -p rw -a log=INLINE",
             'mount' => "mount #{@fsname}" }

    cmds.each do |action, cmd|
      cmde = Mixlib::ShellOut.new(cmd)
      if @current_resource.send(action + 'exist')
        Chef::Log.info(action + ' is already created')
      else
        converge_by("creating #{action}") do
          cmde.run_command
          if cmde.error?
            Chef::Log.error('the command ' + cmd + ' failed')
            Chef::Log.error(cmde.stderr)
            raise
          end
        end
      end
    end
  end
end

action :delete do
  if platform_family?('aix')
    cmds = { 'mount' => "umount #{@fsname}",
             'fs' => "rmfs -r #{@fsname}" }

    cmds.each do |action, cmd|
      cmde = Mixlib::ShellOut.new(cmd)
      if @current_resource.send(action + 'exist')
        converge_by("deleting #{action}") do
          cmde.run_command
          if cmde.error?
            Chef::Log.error('the command ' + cmd + ' failed')
            Chef::Log.error(cmde.stderr)
            raise
          end
        end
      else
        Chef::Log.info(action + ': nothing to do')
      end
    end
  end
end

def load_current_resource
  @current_resource = Chef::Resource::IbmTscmMakefs.new(@new_resource.name)
  @name = @new_resource.name
  @lvname = @new_resource.lvname
  @fsname = @new_resource.fsname
  @fsname = @name if @fsname.nil?
  @vgname = @new_resource.vgname
  @fstype = @new_resource.fstype
  @size = @new_resource.size

  @current_resource.lvexist = true unless shell_out("lslv #{@lvname}").stdout.empty?
  @current_resource.fsexist = true unless shell_out("lsfs #{@fsname}").stdout.empty?
  @current_resource.mountexist = true unless shell_out("mount | grep #{@fsname}").stdout.empty?
end
