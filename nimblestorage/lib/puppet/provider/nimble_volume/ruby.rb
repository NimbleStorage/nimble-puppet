require 'fileutils'
require "net/https"
require "uri"
require "nimblerest"

Puppet::Type.type(:nimble_volume).provide(:nimble_volume) do
    desc "Work on Nimble Array Volumes"
	mk_resource_methods
    def create
        $token=getAuthToken(resource[:transport])
        perfPolicyId = nil
        requestedParams = Hash(resource)
        requestedParams.delete(:provider)
        requestedParams.delete(:ensure)
        requestedParams.delete(:transport)
        requestedParams.delete(:loglevel)
        requestedParams.delete(:perfpolicy)

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
      
          doPUT(resource[:transport]['server'],resource[:transport]['port'],"/v1/volumes/"+volId,{"data"=>$dirtyHash},{"X-Auth-Token"=>$token})
        end
        
    end

    def destroy
        $token=getAuthToken(resource[:transport])
        volId = returnVolId(resource[:name],resource[:transport])
        if volId.nil?
            puts 'Volume '+ resource[:name] + ' not found'
            return nil
        else
            puts 'Removing ' + resource[:name]
            if resource[:force]
              # Put the volume offline
              puts "Specified force=>true. Putting volume offline"
              doPUT(resource[:transport]['server'],resource[:transport]['port'],"/v1/volumes/"+volId,{"data"=>{"online"=>"false"}},{"X-Auth-Token"=>$token})
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
      $token=getAuthToken(resource[:transport])
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
=begin
  def self.prefetch(resources)
  	firstResource = resources.values.first
  	$token=getAuthToken(firstResource[:transport])
    allVolumes = returnAllVolumes(firstResource[:transport])
    resources.each do |name,resource|
    	found = nil
	    allVolumes.each do |volume|
	    	if name.eql? volume["name"]
	    		found = volume
	    		result = { :ensure => :present }
    			result[:name] = volume[:name]
    			result[:id] = volume[:id]
    			resource.provider = new (found,result)
	    		break
	    	end
    	end
    	if found.nil?
    		resource.provider = new (nil, :ensure => :absent)
    	end
    end
    puts resources


  end

  def self.instances  	  
  	    
  end
=end

end
