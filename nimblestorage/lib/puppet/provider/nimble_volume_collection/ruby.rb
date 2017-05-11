require 'fileutils'
require "net/https"
require "uri"
require "nimblerest"
require "facter"

Puppet::Type.type(:nimble_volume_collection).provide(:nimble_volume_collection) do
  desc "Work on Nimble Array Volumes"
  mk_resource_methods

  def create
    perfPolicyId = nil
    requestedParams = Hash.new
    requestedParams[:name] = resource[:name]

    begin
      prottmpl_details = pt_details_api(resource[:transport], resource[:prottmpl_name])
      requestedParams[:prottmpl_id] = prottmpl_details['id'].to_s
    rescue
    end

    doPOST(resource[:transport]['server'], resource[:transport]['port'], "/v1/volume_collections", {"data" => requestedParams}, {"X-Auth-Token" => $token})

  end


  def destroy
    if defined? $vc_id
      if self.listofvols_api(resource)
        list = listofvols_api(resource)
        list.each do |vol|
          doPUT(resource[:transport]['server'], resource[:transport]['port'], "/v1/volumes/"+vol['id'], {"data" => {"volcoll_id" => ""}}, {"X-Auth-Token" => $token})
        end
      end
      doDELETE(resource[:transport]['server'], resource[:transport]['port'], "/v1/volume_collections/" + $vc_id, {"X-Auth-Token" => $token})
    end
  end

  def exists?
    deleteRequested = false
    if resource[:ensure].to_s == "absent"
      deleteRequested = true
    end
    vc_details = vc_details_api(resource[:transport], resource[:name])
    #puts vc_details
    if vc_details == nil
      return false
    else
      $vc_id = vc_details['id']
      return true
    end
  end


  def listofvols_api(resource)
    vc_details = vc_details_api(resource[:transport], resource[:name])
    if vc_details == nil
      return false
    end
    return vc_details['volume_list']
  end

  def del_vol_list(list)
    doPUT(resource[:transport]['server'], resource[:transport]['port'], "/v1/volumes/"+volId, {"data" => $dirtyHash}, {"X-Auth-Token" => $token})
  end

end
