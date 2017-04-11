require 'fileutils'
require "net/https"
require "uri"
require "nimblerest"

Puppet::Type.type(:nimble_initiator).provide(:nimble_initiator) do
  desc "Work on Nimble Array initiators"

  def create

    $token=Facter.value('token')
    requestedParams = Hash(resource)
    requestedParams.delete(:provider)
    requestedParams.delete(:ensure)
    requestedParams.delete(:transport)
    requestedParams.delete(:loglevel)
    requestedParams.delete(:name)
    requestedParams.delete(:notify)
    requestedParams.delete(:before)
    requestedParams[:iqn] = Facter.value(:iscsi_initiator)
    puts "Creating New Initiator #{requestedParams[:iqn]}"
    initiatorgroupid = returnInitiatorGroupId(resource[:transport], resource[:name])
    if initiatorgroupid.nil?
      raise "Can't find non existing initiator group #{resource[:name]}"
    else
      puts "Will assign iqn: '#{requestedParams[:iqn]}' with label #{resource[:label]} to group #{resource[:name]}"
      requestedParams[:initiator_group_id] = initiatorgroupid

      if $dirtyHash.size == 0
        puts "Creating New initiator #{resource[:name]}"
        doPOST(resource[:transport]['server'], resource[:transport]['port'], "/v1/initiators", {"data" => requestedParams}, {"X-Auth-Token" => $token})
      else
        puts "Updating existing initiator #{resource[:label]} . Values to change #{$dirtyHash}"
        initiatorId = returnInitiatorId(resource[:transport], requestedParams[:iqn], resource[:ip_address], resource[:label])
        if(initiatorId)
          doDELETE(resource[:transport]['server'], resource[:transport]['port'], "/v1/initiators/"+initiatorId, {"X-Auth-Token" => $token})
          doPOST(resource[:transport]['server'], resource[:transport]['port'], "/v1/initiators", {"data" => requestedParams}, {"X-Auth-Token" => $token})
        end
      end
    end
  end

  def destroy
    $token=Facter.value('token')
    initiatorId = returnInitiatorId(resource[:transport], requestedParams[:iqn], resource[:ip_address], resource[:label])
    doDELETE(resource[:transport]['server'], resource[:transport]['port'], "/v1/initiators/"+initiatorId, {"X-Auth-Token" => $token})
  end

  def exists?
    deleteRequested = false
    if resource[:ensure].to_s == "absent"
      deleteRequested = true
    end
    requestedParams = Hash(resource)
    requestedParams[:iqn] = Facter.value(:iscsi_initiator)
    $dirtyHash=Hash.new
    allinitiators = returnAllinitiators(resource[:transport])
    allinitiators.each do |initiator|
      if (requestedParams[:iqn].eql? initiator["iqn"]) || (resource["ip_address"].eql? initiator["ip_address"]) || (resource["label"].eql? initiator["label"])
        if deleteRequested
          return true
        end
        requestedParams.each do |k, v|
          key = k.to_s
          if initiator.key?(key)
            if initiator[key].to_s != v.to_s
              $dirtyHash[key] = v
            end
          end
        end
        if $dirtyHash.size != 0
          return false
        else
          if resource["name"] != initiator["initiator_group_name"]
            $dirtyHash["group_id"] = initiator["initiator_group_id"]
               return false
             end
          return true
        end
      end
    end
    return false
  end
end
