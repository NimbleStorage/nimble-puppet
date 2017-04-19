require 'fileutils'
require "net/https"
require "uri"
require "nimblerest"

Puppet::Type.type(:nimble_fs_mount).provide(:nimble_fs_mount) do
  desc "Work on Nimble Array initiators"

  def pre_flight(serial_num)
    return Puppet::Util::Execution.execute('find /dev -name "[uuid]*' + serial_num + '*" | tr \'\n\' \' \' | cut -d \' \' -f1')
  end

  def reDiscoverRefresh
    if system("/usr/sbin/iscsiadm -m node -p #{$iscsiadm['target']}:#{$iscsiadm['port']}")
      Puppet::Util::Execution.execute("/usr/sbin/iscsiadm -m node -R -T #{$iscsiadm[:target_name]} -p #{$iscsiadm['target']}:#{$iscsiadm['port']}")
      if $device[:mp].to_s == "true"
        Puppet::Util::Execution.execute("/usr/sbin/multipath -r")
      end
      if !self.if_mount($device[:path])
        if $device[:fs].to_s == 'xfs'
        Puppet::Util::Execution.execute("xfs_growfs #{$device[:path]}")
      else
        Puppet::Util::Execution.execute("resize2fs #{$device[:path]}")
        end
      end
    end
  end

  def iscsireDiscover
    if system("/usr/sbin/iscsiadm -m node -p #{$iscsiadm['target']}:#{$iscsiadm['port']}")
      if system("/usr/sbin/iscsiadm -m discovery -t st -p #{$iscsiadm['target']}:#{$iscsiadm['port']}")
        if $device[:mp].to_s == "true"
          Puppet::Util::Execution.execute("/usr/sbin/multipath -r")
        end
      else
        return nil
      end
    end
  end

  def iscsiLogin
    if self.isIscsiLoggedIn
      return true
    end
    if system("/usr/sbin/iscsiadm -m discovery -t st -p #{$iscsiadm['target']}:#{$iscsiadm['port']} | grep #{$iscsiadm[:target_name]}")
      if Puppet::Util::Execution.execute("/usr/sbin/iscsiadm -m node -p #{$iscsiadm['target']}:#{$iscsiadm['port']}")
        if Puppet::Util::Execution.execute("/usr/sbin/iscsiadm -m node -l -T #{$iscsiadm[:target_name]} -p #{$iscsiadm['target']}:#{$iscsiadm['port']}")
          if $device[:mp].to_s == "true"
            Puppet::Util::Execution.execute("/usr/sbin/multipath -r")
          end
          return true
        else
          return false
        end
      end
    else
      return false
    end
  end

  def iscsiLogout
    if self.isIscsiLoggedIn
      if system("/usr/sbin/iscsiadm -m node -p #{$iscsiadm['target']}:#{$iscsiadm['port']}")
        if Puppet::Util::Execution.execute("/usr/sbin/iscsiadm -m node -u -T #{$iscsiadm[:target_name]} -p #{$iscsiadm['target']}:#{$iscsiadm['port']}")
          Puppet::Util::Execution.execute("/usr/sbin/iscsiadm -m discovery -t st -p #{$iscsiadm['target']}:#{$iscsiadm['port']}")
          if $device[:mp].to_s == "true"
            Puppet::Util::Execution.execute("/usr/sbin/multipath -r")
          end
          return true
        else
          return false
        end
      end
    end
  end

  def iscsiLogoutAll
    Puppet::Util::Execution.execute("/usr/sbin/iscsiadm -m node -u -p #{$iscsiadm['target']}:#{$iscsiadm['port']}")
  end

  def isIscsiLoggedIn
    return system("/usr/sbin/iscsiadm -m session | grep -m 1 #{$iscsiadm[:target_name]}")
  end

  def removefstabentry
    Puppet::Util::Execution.execute("/usr/bin/sed -i /#{$device[:uuid]}/d /etc/fstab")
  end

  def fstabentry
    self.removefstabentry
    if resource[:ensure].to_s == 'present'
      Puppet::Util::Execution.execute("echo 'UUID=#{$device[:uuid]}  #{$device[:mount_point]}  #{$device[:fs]} _netdev,auto,x-systemd.requires=#{$device[:originalPath]} 0 0' | tee -a /etc/fstab")
    end
  end

  def fetch_data(mp, serial_num)
    sleep(4)
    if mp.to_s == "true"
      self.retrieve_data_w_multipath(serial_num)
    else
      self.retrieve_data_wo_multipath(serial_num)
    end
  end

  def trim(pl)
    return pl.chomp
  end

  def retrieve_data_wo_multipath(serial_num)
    $device[:originalPath] = trim(Puppet::Util::Execution.execute('find /dev -name "[scsi]*' + serial_num + '*" | tr \'\n\' \' \' | cut -d \' \' -f1'))
    if $device[:originalPath] != nil
      $device[:map] = trim(Puppet::Util::Execution.execute("ls -l "+ $device[:originalPath] +" | awk '{print$11}' | cut -d '/' -f3  "))
      $device[:path] = trim(Puppet::Util::Execution.execute('lsblk -fp | grep -m 1 '+$device[:map]+' | awk \'{print$1}\' '))
      $device[:fs] = trim(Puppet::Util::Execution.execute('lsblk -fp | grep -m 1 '+$device[:map]+' | awk \'{print$2}\'   '))
      $device[:label] = trim(Puppet::Util::Execution.execute('lsblk -fp | grep -m 1 '+$device[:map]+' | awk \'{print$3}\'  '))
      $device[:uuid] = trim(Puppet::Util::Execution.execute('lsblk -fp | grep -m 1 '+$device[:map]+' | awk \'{print$4}\' '))
      $device[:mount_point] = trim(Puppet::Util::Execution.execute('lsblk -fp | grep -m 1 '+$device[:map]+' | awk \'{print$5}\' '))
    end
  end

  def retrieve_data_w_multipath(serial_num)
    $device[:originalPath] = trim(Puppet::Util::Execution.execute('find /dev -name "[uuid]*' + serial_num + '*" | tr \'\n\' \' \' | cut -d \' \' -f1'))
    if $device[:originalPath] != nil
      $device[:map] = trim(Puppet::Util::Execution.execute("multipath -ll | grep -m 1 #{serial_num} | cut -d ' ' -f1 "))
      $device[:path] = trim(Puppet::Util::Execution.execute('lsblk -fpl | grep -m 1 '+$device[:map]+' | awk \'{print$1}\' '))
      $device[:fs] = trim(Puppet::Util::Execution.execute('lsblk -fpl | grep -m 1 '+$device[:map]+' | awk \'{print$2}\'  '))
      $device[:label] = trim(Puppet::Util::Execution.execute('lsblk -fpl | grep -m 1 '+$device[:map]+' | awk \'{print$3}\' '))
      $device[:uuid] = trim(Puppet::Util::Execution.execute('lsblk -fpl | grep -m 1 '+$device[:map]+' | awk \'{print$4}\' '))
      $device[:mount_point] = trim(Puppet::Util::Execution.execute('lsblk -fpl | grep -m 1 '+$device[:map]+' | awk \'{print$5}\' '))
    end
  end

  def unmount(path)
    if !self.if_mount(path)
      Puppet::Util::Execution.execute('umount ' + path)
      self.removefstabentry
      self.iscsiLogout
    end
  end

  def mount(path, mount_point)
    if self.if_mount(path)
      self.removefstabentry
      Puppet::Util::Execution.execute('mount ' + path + ' ' + mount_point)
    end
  end

  def if_mount(path)
    return !system('mount | grep ' + path)
  end

  def create
    begin
      if $vol_details['data'][0]['serial_number'] != nil
        serial_num = $vol_details['data'][0]['serial_number']
        self.iscsireDiscover

        if self.pre_flight(serial_num) != nil && self.iscsiLogin

          if Facter.value(resource[:target_vol]).to_s == 'refresh'
            puts 'Re Discovering and refreshing'
            self.reDiscoverRefresh
          end

          $device = Hash.new

          self.fetch_data("#{resource[:mp]}", serial_num)

          if $device[:fs].to_s.empty?
            Puppet::Util::Execution.execute('echo "y" | mkfs -t '+resource[:fs]+' ' + $device[:path])
          elsif $device[:fs].to_s != resource[:fs].to_s
            if !self.if_mount($device[:path])
              self.unmount($device[:path])
            end
            if resource[:fs] == 'xfs'
              Puppet::Util::Execution.execute('echo "y" | mkfs -t '+resource[:fs]+' -f ' + $device[:path])
            else
              Puppet::Util::Execution.execute('echo "y" | mkfs -t '+resource[:fs]+' ' + $device[:path])
            end
          end

          self.fetch_data("#{resource[:mp]}", serial_num)

          if $device[:label] != resource[:label]
            if $device[:fs].to_s != 'xfs'
              if self.if_mount($device[:path])
                Puppet::Util::Execution.execute('e2label '+$device[:path]+' '+ resource[:label])
              else
                self.unmount($device[:path])
                Puppet::Util::Execution.execute('e2label '+$device[:path]+' '+ resource[:label])
              end
            else
              if self.if_mount($device[:path])
                Puppet::Util::Execution.execute('xfs_admin -L ' + resource[:label] + ' ' + $device[:path])
              else
                self.unmount($device[:path])
                Puppet::Util::Execution.execute('xfs_admin -L ' + resource[:label] + ' ' + $device[:path])
              end
            end
          end

          unless File.directory?(resource[:mount_point])
            Puppet::Util::Execution.execute('mkdir -p ' + resource[:mount_point])
          end

          self.iscsireDiscover

          self.fetch_data("#{resource[:mp]}", serial_num)

          self.mount($device[:path], resource[:mount_point])

          self.fetch_data("#{resource[:mp]}", serial_num)

          self.fstabentry

          self.reDiscoverRefresh
        else
          puts "Target not Discoverable"
        end

      end
    rescue Exception => e
      puts e.message
      puts e.backtrace.inspect
    end

  end

  def destroy
    $vol_details = returnVolDetails(resource[:transport], resource[:target_vol])
    if $vol_details['data'][0]['serial_number'] != nil
      serial_num = $vol_details['data'][0]['serial_number']
      if self.pre_flight(serial_num) != nil
        $device = Hash.new
        self.fetch_data("#{resource[:mp]}", serial_num)
        if !self.if_mount($device[:path])
          self.unmount($device[:path])
        end
      else
        return false
      end
    end
  end

  def exists?
    deleteRequested = false
    if resource[:ensure].to_s == "absent"
      deleteRequested = true
    end
    $device = Hash.new
    $device[:mp] = resource[:mp]
    $iscsiadm = Hash(resource[:config])
    $vol_details = returnVolDetails(resource[:transport], resource[:target_vol])
    if $vol_details['data'].size !=0 && $vol_details['data'][0]['serial_number'] != nil
      serial_num = $vol_details['data'][0]['serial_number']
      $iscsiadm[:target_name] = $vol_details['data'][0]['target_name']
      if !deleteRequested
        self.iscsireDiscover
        if !self.iscsiLogin
          return false
        end
      end
      if self.pre_flight(serial_num) != nil
        self.fetch_data("#{resource[:mp]}", serial_num)
        if Facter.value(resource[:target_vol]).to_s == 'refresh' && deleteRequested != true
          return false
        end
        if $device[:map] == nil
          return false
        end
        if self.if_mount($device[:path]) && deleteRequested == true
          self.iscsiLogout
          return false
        else
          if $device[:fs] != resource[:fs] || $device[:mount_point] != resource[:mount_point] || $device[:label] != resource[:label]
            if deleteRequested
              return true
            else
              return false
            end
          end
          return true
        end
      else
        return false
      end
    else
      if deleteRequested
        return false
      else
        return true
      end
    end
  end
end

