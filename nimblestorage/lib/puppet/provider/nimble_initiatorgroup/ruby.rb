require 'fileutils'
require "net/https"
require "uri"
require "nimblerest"

Puppet::Type.type(:nimble_initiatorgroup).provide(:nimble_initiatorgroup) do
    desc "Work on Nimble Array initiator groups"

    def create
        $token=getAuthToken(resource[:transport])
        requestedParams = Hash(resource)
        requestedParams.delete(:provider)
        requestedParams.delete(:ensure)
        requestedParams.delete(:transport)
        requestedParams.delete(:loglevel)
        requestedParams.delete(:notify)

       subnetsInArray=returnAllSubnets(resource[:transport])
        unless resource[:target_subnets].nil?
            idsToPut=Array.new
            resource[:target_subnets].each do |subnetreq|
              subnetsInArray.each do |subnetInArray|
                if subnetreq == subnetInArray["name"]
                    idsToPut.push({"id" => subnetInArray["id"], "label" => subnetreq})
                end
              end
            end
          end

          if idsToPut.length == resource[:target_subnets].length
            if $dirtyHash.size == 0
              requestedParams[:target_subnets] = idsToPut
            else
              $dirtyHash["target_subnets"] = idsToPut
            end
            
          else
            raise "Not all subnets were found in the array #{resource[:target_subnets]}"
          end


        if $dirtyHash.size == 0
          puts "Creating New initiatorgroup #{resource[:name]}"          
          puts(requestedParams)
          doPOST(resource[:transport]['server'],resource[:transport]['port'],"/v1/initiator_groups",{"data"=>requestedParams},{"X-Auth-Token"=>$token})
        else
          puts "Updating existing initiatorgroup #{resource[:name]} . Values to change #{$dirtyHash}"
          initiatorgroupid = returnInitiatorGroupId(resource[:transport],resource[:name])
          doPUT(resource[:transport]['server'],resource[:transport]['port'],"/v1/initiator_groups/"+initiatorgroupid,{"data"=>$dirtyHash},{"X-Auth-Token"=>$token})
        end


    end

    def destroy
        $token=getAuthToken(resource[:transport])
        initiatorgroupid = returnInitiatorGroupId(resource[:transport],resource[:name])
        doDELETE(resource[:transport]['server'],resource[:transport]['port'],"/v1/initiator_groups/"+initiatorgroupid,{"X-Auth-Token"=>$token})
    end

    def exists?
      deleteRequested = false
      if resource[:ensure].to_s == "absent"
        deleteRequested = true
      end
      requestedParams = Hash(resource)
      $dirtyHash=Hash.new
      $token=getAuthToken(resource[:transport])
      allinitiatorGroups = returnAllinitiatorGroups(resource[:transport])
      allinitiatorGroups.each do |initiatorgroup|
          if resource[:name].eql? initiatorgroup["name"]
            if deleteRequested
              return true
            end
            requestedParams.each do|k,v|
              key = k.to_s
              if initiatorgroup.key?(key)
                if initiatorgroup[key].to_s != v.to_s
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
end
