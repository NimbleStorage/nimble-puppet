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

end
