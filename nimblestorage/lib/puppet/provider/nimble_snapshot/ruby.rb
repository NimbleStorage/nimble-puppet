require 'fileutils'
require "net/https"
require "uri"
require "nimblerest"

Puppet::Type.type(:nimble_snapshot).provide(:nimble_snapshot) do
    desc "Work on Nimble Array Snapshots"

    def create
        $token=Facter.value('token')
        volId = returnVolId(resource[:vol_name],resource[:transport])
        if volId.nil?
          raise "Can't create snapshot of non-existent volume " + resource[:vol_name]
        end
        createHash = Hash.new
        createHash["name"] = resource[:name]
        createHash["vol_id"] = volId
        unless resource[:description].nil?
          createHash["description"] = resource[:description]
        end
        unless resource[:online].nil?
          createHash["online"] = resource[:online]
        end
        unless resource[:writable].nil?
          createHash["writable"] = resource[:writable]
        end
        doPOST(resource[:transport]['server'],resource[:transport]['port'],"/v1/snapshots",{"data"=>createHash},{"X-Auth-Token"=>$token})
    end

    def destroy
        $token=Facter.value('token')
        snapshotId = returnSnapshotId(resource[:name],resource[:vol_name],resource[:transport])
        doDELETE(resource[:transport]['server'],resource[:transport]['port'],"/v1/snapshots/"+snapshotId,{"X-Auth-Token"=>$token})
    end

    def exists?
      $token=Facter.value('token')
      volId = returnVolId(resource[:vol_name],resource[:transport])
      if volId.nil?
        raise "Can't find snapshot of non-existent volume " + resource[:vol_name]
      end
      allSnapshots = returnAllSnapshots(resource[:vol_name],resource[:transport])
      allSnapshots.each do |snapshot|
          if resource[:name].eql? snapshot["name"]
            return true
          end
      end
      return false
    end
end
