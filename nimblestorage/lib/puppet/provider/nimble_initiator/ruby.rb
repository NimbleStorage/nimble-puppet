require 'fileutils'
require "net/https"
require "uri"
require "nimblerest"

Puppet::Type.type(:nimble_initiator).provide(:nimble_initiator) do
    desc "Work on Nimble Array initiators"

    def create
        $token=getAuthToken(resource[:transport])
        requestedParams = Hash(resource)
        requestedParams.delete(:provider)
        requestedParams.delete(:ensure)
        requestedParams.delete(:transport)
        requestedParams.delete(:loglevel)
        requestedParams.delete(:name)
        requestedParams.delete(:notify)
        puts "Creating New initiatorgroup #{resource[:iqn]}"          
        initiatorgroupid = returnInitiatorGroupId(resource[:transport],resource[:name])
        if initiatorgroupid.nil?
            raise "Can't find non existing initiator group #{resource[:name]}"
        else
            puts "Will assign #{resource[:iqn]} to group #{resource[:name]}"
            requestedParams[:initiator_group_id] = initiatorgroupid
        end
        puts requestedParams
        doPOST(resource[:transport]['server'],resource[:transport]['port'],"/v1/initiators",{"data"=>requestedParams},{"X-Auth-Token"=>$token})


    end

    def destroy
        $token=getAuthToken(resource[:transport])
        initiatorgroupid = returnInitiatorGroupId(resource[:transport],resource[:name])
        doDELETE(resource[:transport]['server'],resource[:transport]['port'],"/v1/initiator_groups/"+initiatorgroupid,{"X-Auth-Token"=>$token})
    end

    def exists?
      puts resource[:iqn]
      deleteRequested = false
      if resource[:ensure].to_s == "absent"
        deleteRequested = true
      end
      requestedParams = Hash(resource)
      $token=getAuthToken(resource[:transport])
      allinitiators = returnAllinitiators(resource[:transport])
      allinitiators.each do |initiator|
          if resource[:iqn].eql? initiator["iqn"]
              return true
          end
      end
      return false
    end
end
