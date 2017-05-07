require 'fileutils'
require "net/https"
require "uri"
require "nimblerest"
require "json"

Puppet::Type.type(:nimble_acr).provide(:nimble_acr) do
  desc "Work on Nimble Array Volume Access Control Records"

  def create
    $token=Facter.value('token')
    requestedParams = Hash.new
    requestedParams[:apply_to] = resource[:apply_to]
    requestedParams[:chap_user_id] = returnChapIdFromName(resource[:transport], resource[:chap_user])
    requestedParams[:vol_id] = returnVolId(resource[:volume_name], resource[:transport])
    requestedParams[:initiator_group_id] = returnInitiatorGroupId(resource[:transport], resource[:initiator_group])
    if $dirtyHash != ''
      doDELETE(resource[:transport]['server'], resource[:transport]['port'], "/v1/access_control_records/#{$dirtyHash}", {"X-Auth-Token" => $token})
      doPOST(resource[:transport]['server'], resource[:transport]['port'], "/v1/access_control_records", {"data" => requestedParams}, {"X-Auth-Token" => $token})
    else
      doPOST(resource[:transport]['server'], resource[:transport]['port'], "/v1/access_control_records", {"data" => requestedParams}, {"X-Auth-Token" => $token})
    end


  end

  def destroy
    $token=Facter.value('token')
    volId = returnVolId(resource[:volume_name], resource[:transport])
    if !volId.nil?
      volDetails = returnVolDetails(resource[:transport], resource[:volume_name])
    else
      puts 'Volume '+ resource[:volume_name] + ' not found'
      return nil
    end

    self.putVolumeOffline(resource)
    doDELETE(resource[:transport]['server'], resource[:transport]['port'], "/v1/access_control_records/#{$dirtyHash}", {"X-Auth-Token" => $token})
  end

  def exists?
    deleteRequested = false
    if resource[:ensure].to_s == "absent"
      deleteRequested = true
    end
    $dirtyHash = String.new
    requestedParams = Hash(resource)
    requestedParams[:vol_id] = returnVolId(resource[:volume_name], resource[:transport])
    if requestedParams[:vol_id] == nil && !deleteRequested
      return true
    elsif requestedParams[:vol_id] == nil && deleteRequested
      return false
    end
    acrs = returnACRDetails(resource[:transport], requestedParams[:vol_id])
    if acrs.length == 0
      return false
    else
      acrs.each do |acr|
        if acr['chap_user_name'] != resource[:chap_user] || acr['initiator_group_name'] != resource[:initiator_group] || acr['vol_name'] != resource[:volume_name] || acr['apply_to'] != resource[:apply_to]
          $dirtyHash = acr['id'].to_s
          return false
        end
        if deleteRequested
          $dirtyHash = acr['id'].to_s
          return true
        end
      end
      return true
    end

  end

  def pre_flight(mp, serial_num)
    if mp.to_s == "true"
      return Puppet::Util::Execution.execute('find /dev -name "[uuid]*' + serial_num + '*" | tr "\n" " " ')
    else
      return Puppet::Util::Execution.execute('find /dev -name "[scsi]*' + serial_num + '*" | tr "\n" " " ')
    end
  end

  def fetch_data(mp, serial_num)
    if mp.to_s == "true"
      self.retrieve_data_w_multipath(serial_num)
    else
      self.retrieve_data_wo_multipath(serial_num)
    end
  end

  def iscsireDiscover
    if system("/usr/sbin/iscsiadm -m node -p #{$device[:target]}:#{$device[:port]} >> /dev/null 2>&1")
      if system("/usr/sbin/iscsiadm -m discovery -t st -p #{$device[:target]}:#{$device[:port]} >> /dev/null 2>&1")
        if $device[:mp].to_s == "true"
          Puppet::Util::Execution.execute("/usr/sbin/multipath -r")
        end
      else
        return nil
      end
    end
  end

  def isIscsiLoggedIn
    return system("/usr/sbin/iscsiadm -m session | grep -m 1 #{$device[:target_name]}")
  end

  def trim(pl)
    return pl.chomp
  end

  def retrieve_data_wo_multipath(serial_num)
    begin
      $device[:originalPath] = trim(Puppet::Util::Execution.execute('find /dev -name "[scsi]*' + serial_num + '*" | tr \'\n\' \' \' | cut -d \' \' -f1'))
      if $device[:originalPath] != nil
        $device[:map] = trim(Puppet::Util::Execution.execute("ls -l "+ $device[:originalPath] +" | awk '{print$11}' | cut -d '/' -f3  "))
        $device[:path] = trim(Puppet::Util::Execution.execute('lsblk -fp | grep -m 1 '+$device[:map]+' | awk \'{print$1}\' '))
        $device[:fs] = trim(Puppet::Util::Execution.execute('lsblk -fp | grep -m 1 '+$device[:map]+' | awk \'{print$2}\'   '))
        $device[:label] = trim(Puppet::Util::Execution.execute('lsblk -fp | grep -m 1 '+$device[:map]+' | awk \'{print$3}\'  '))
        $device[:uuid] = trim(Puppet::Util::Execution.execute('lsblk -fp | grep -m 1 '+$device[:map]+' | awk \'{print$4}\' '))
        $device[:mount_point] = trim(Puppet::Util::Execution.execute('lsblk -fp | grep -m 1 '+$device[:map]+' | awk \'{print$5}\' '))
      end
    rescue => e
    end
  end

  def retrieve_data_w_multipath(serial_num)
    begin
      $device[:originalPath] = trim(Puppet::Util::Execution.execute('find /dev -name "[uuid]*' + serial_num + '*" | tr \'\n\' \' \' | cut -d \' \' -f1 '))
      if $device[:originalPath] != nil
        $device[:map] = trim(Puppet::Util::Execution.execute("multipath -ll | grep -m 1 #{serial_num} | cut -d ' ' -f1 "))
        $device[:path] = trim(Puppet::Util::Execution.execute('lsblk -fpl | grep -m 1 '+$device[:map]+' | awk \'{print$1}\' '))
        $device[:fs] = trim(Puppet::Util::Execution.execute('lsblk -fpl | grep -m 1 '+$device[:map]+' | awk \'{print$2}\'  '))
        $device[:label] = trim(Puppet::Util::Execution.execute('lsblk -fpl | grep -m 1 '+$device[:map]+' | awk \'{print$3}\' '))
        $device[:uuid] = trim(Puppet::Util::Execution.execute('lsblk -fpl | grep -m 1 '+$device[:map]+' | awk \'{print$4}\' '))
        $device[:mount_point] = trim(Puppet::Util::Execution.execute('lsblk -fpl | grep -m 1 '+$device[:map]+' | awk \'{print$5}\' '))
      end
    rescue => e
    end
  end

  def unmount(path)
    if self.if_mount(path)
      Puppet::Util::Execution.execute('umount ' + path)
      self.removefstabentry
      self.iscsiLogout
    end
  end

  def if_mount(path)
    return system('mount | grep ' + path)
  end

  def iscsiLogout
    if !self.isIscsiLoggedIn
      return true
    end
    if system("/usr/sbin/iscsiadm -m node -p #{$device[:target]}:#{$device[:port]} >> /dev/null 2>&1")
      if Puppet::Util::Execution.execute("/usr/sbin/iscsiadm -m node -u -T #{$device[:target_name]} -p #{$device[:target]}:#{$device[:port]} >> /dev/null 2>&1")
        Puppet::Util::Execution.execute("/usr/sbin/iscsiadm -m discovery -t st -p #{$device[:target]}:#{$device[:port]} >> /dev/null 2>&1")
        if $device[:mp].to_s == "true"
          Puppet::Util::Execution.execute("/usr/sbin/multipath -r")
        end
        return true
      else
        return false
      end
    end
  end

  def removefstabentry
    Puppet::Util::Execution.execute("/usr/bin/sed -i /#{$device[:uuid]}/d /etc/fstab")
  end

  def putVolumeOffline(resource)
    volId = returnVolId(resource[:volume_name], resource[:transport])
    if !volId.nil?
      volDetails = returnVolDetails(resource[:transport], resource[:volume_name])
    else
      puts 'Volume '+ resource[:volume_name] + ' not found'
      return nil
    end

    $device = Hash.new
    $device[:serial_num] = volDetails['data'][0]['serial_number']
    $device[:target_name] = volDetails['data'][0]['target_name']
    $device[:target] = resource[:config]['target']
    $device[:port] = resource[:config]['port']
    $device[:mp] = resource[:mp]

    if self.isIscsiLoggedIn
      if self.pre_flight($device[:mp], $device[:serial_num]) != nil
        self.fetch_data($device[:mp], $device[:serial_num])
        self.unmount($device[:path])
        puts 'Published: Remove Volume if access not found'
      end
    end
  end
end
