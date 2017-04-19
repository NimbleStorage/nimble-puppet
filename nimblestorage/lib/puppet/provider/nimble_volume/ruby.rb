require 'fileutils'
require "net/https"
require "uri"
require "nimblerest"
require "facter"

Puppet::Type.type(:nimble_volume).provide(:nimble_volume) do
    desc "Work on Nimble Array Volumes"
	mk_resource_methods
    def create
      $token=Facter.value('token')
        perfPolicyId = nil
        requestedParams = Hash(resource)
        requestedParams.delete(:provider)
        requestedParams.delete(:ensure)
        requestedParams.delete(:transport)
        requestedParams.delete(:loglevel)
        requestedParams.delete(:perfpolicy)
        requestedParams.delete(:config)
        requestedParams.delete(:mp)

        unless resource[:perfpolicy].nil?
           perfPolicyId = returnPerfPolicyId(resource[:transport],resource[:perfpolicy])
           if perfPolicyId.nil?
               raise resource[:perfpolicy] + " does not exist"
           end
           requestedParams["perfpolicy_id"] = perfPolicyId
        end
        if $dirtyHash.size == 0
          requestedParams.delete(:force)
          puts "Creating New Volume #{resource[:name]}"
          doPOST(resource[:transport]['server'],resource[:transport]['port'],"/v1/volumes",{"data"=>requestedParams},{"X-Auth-Token"=>$token})
        else
          volId = returnVolId(resource[:name],resource[:transport])          
          puts "Updating existing Volume #{resource[:name]} with id = #{volId}. Values to change #{$dirtyHash}"
          if resource[:force].to_s == "true"
            $dirtyHash[:force] = true
          end
          if $dirtyHash['size']
            Facter.add(resource[:name]) do
              setcode do
                'refresh'
              end
            end
          end
          if $dirtyHash['online'].to_s == 'false'
            self.putVolumeOffline(resource)
          end
          $json = doPUT(resource[:transport]['server'],resource[:transport]['port'],"/v1/volumes/"+volId,{"data"=>$dirtyHash},{"X-Auth-Token"=>$token})
        end
        
    end

    def destroy
        $token=Facter.value('token')
        volId = returnVolId(resource[:name],resource[:transport])
        if !volId.nil?
          volDetails = returnVolDetails(resource[:transport], resource[:name])
        else
          puts 'Volume '+ resource[:name] + ' not found'
          return nil
        end

        self.putVolumeOffline(resource)


        if volId.nil?
            puts 'Volume '+ resource[:name] + ' not found'
            return nil
        else
            puts 'Removing ' + resource[:name]
            if resource[:force]
              # Put the volume offline
              puts "Specified force=>true. Putting volume offline"
              doPUT(resource[:transport]['server'],resource[:transport]['port'],"/v1/volumes/"+volId,{"data"=>{"online"=>"false", "force" => "true"}},{"X-Auth-Token"=>$token})
              # Delete all Snapshots
              puts "Specified force=>true. Deleting all snapshots"
              allSnaps = returnAllSnapshots(resource[:name],resource[:transport])
              allSnaps.each do |snap|
                  puts "\tDeleting " + snap["name"]
                  doDELETE(resource[:transport]['server'],resource[:transport]['port'],"/v1/snapshots/"+snap["id"],{"X-Auth-Token"=>$token})
              end
              doPUT(resource[:transport]['server'],resource[:transport]['port'],"/v1/volumes/"+volId,{"data"=>{"volcoll_id"=>""}},{"X-Auth-Token"=>$token})
              doDELETE(resource[:transport]['server'],resource[:transport]['port'],"/v1/volumes/"+volId,{"X-Auth-Token"=>$token})
            else
              doPUT(resource[:transport]['server'],resource[:transport]['port'],"/v1/volumes/"+volId,{"data"=>{"online"=>"false"}},{"X-Auth-Token"=>$token})
              doDELETE(resource[:transport]['server'],resource[:transport]['port'],"/v1/volumes/"+volId,{"X-Auth-Token"=>$token})
            end
        end
    end
    
    def exists?
      deleteRequested = false
      if resource[:ensure].to_s == "absent"
        deleteRequested = true
      end
      requestedParams = Hash(resource)
      $dirtyHash=Hash.new
      $token=Facter.value('token')
      allVolumes = returnAllVolumes(resource[:transport])
      allVolumes.each do |volume|
          if resource[:name].eql? volume["name"]
            if deleteRequested
              return true
            end
            requestedParams.each do|k,v|
              key = k.to_s
              if volume.key?(key)
                if volume[key].to_s != v.to_s
                  $dirtyHash[key] = v                  
                end                
              end              
            end
            if $dirtyHash.size != 0
              return false
            else
              return true
            end            
          end
      end
      return false      
    end

    def pre_flight(serial_num)
      return Puppet::Util::Execution.execute('find /dev -name "[uuid]*' + serial_num + '*" | tr "\n" " " ')
    end

    def fetch_data(mp, serial_num)
      sleep(5)
      if mp.to_s == "true"
        self.retrieve_data_w_multipath(serial_num)
      else
        self.retrieve_data_wo_multipath(serial_num)
      end
    end

    def iscsireDiscover
      if system("/usr/sbin/iscsiadm -m node -p #{$device[:target]}:#{$device[:port]}")
        if system("/usr/sbin/iscsiadm -m discovery -t st -p #{$device[:target]}:#{$device[:port]}")
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
      $device[:originalPath] = trim(Puppet::Util::Execution.execute('find /dev -name "[uuid]*' + serial_num + '*" | tr \'\n\' \' \' | cut -d \' \' -f1 '))
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

    def if_mount(path)
      return !system('mount | grep ' + path)
    end

    def iscsiLogout
      if system("/usr/sbin/iscsiadm -m node -p #{$device[:target]}:#{$device[:port]}")
        if Puppet::Util::Execution.execute("/usr/sbin/iscsiadm -m node -u -T #{$device[:target_name]} -p #{$device[:target]}:#{$device[:port]}" )
          Puppet::Util::Execution.execute("/usr/sbin/iscsiadm -m discovery -t st -p #{$device[:target]}:#{$device[:port]}")
          if $device[:mp].to_s == "true"
            Puppet::Util::Execution.execute("/usr/sbin/multipath -r" )
          end
          return true
        else
          return false
        end
      end
    end

    def removefstabentry
      Puppet::Util::Execution.execute("/usr/bin/sed -i /#{$device[:uuid]}/d /etc/fstab" )
    end

  def putVolumeOffline(resource)
    volId = returnVolId(resource[:name],resource[:transport])
    if !volId.nil?
      volDetails = returnVolDetails(resource[:transport], resource[:name])
    else
      puts 'Volume '+ resource[:name] + ' not found'
      return nil
    end

    $device = Hash.new
    $device[:serial_num] = volDetails['data'][0]['serial_number']
    $device[:target_name] = volDetails['data'][0]['target_name']
    $device[:target] = resource[:config]['target']
    $device[:port] = resource[:config]['port']
    $device[:mp] = resource[:mp]

    if self.pre_flight($device[:serial_num]) != nil
      self.fetch_data($device[:mp], $device[:serial_num])
      if !self.if_mount($device[:path])
        self.unmount($device[:path])
      else
        if self.isIscsiLoggedIn
          self.iscsiLogout
        end
      end
      self.iscsireDiscover
    end

  end


end
