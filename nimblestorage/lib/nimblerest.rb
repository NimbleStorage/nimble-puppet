# This file contains necessary REST methods to interact with objects
# in a nimble storage array like volumes, snapshots etc

require 'fileutils'
require "net/https"
require "uri"


# Do a HTTP Put.
def doPUT(server, port, path, postData, header=nil)
  server='https://'+server+':'+port.to_s+path
  uri = URI.parse(server)
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  http.verify_mode = OpenSSL::SSL::VERIFY_NONE
  request = Net::HTTP::Put.new(uri.request_uri, header)
  request.body = postData.to_json
  response = http.request(request)
  case response
    when Net::HTTPSuccess
      return JSON.parse response.body
    when Net::HTTPConflict
      retVal = JSON.parse response.body
      raise retVal["messages"].to_s
    when Net::HTTPUnauthorized
      raise "Unauthorized"
    else
      raise response.body
  end
end

# Do a HTTP Get.
def doGET(server, port, path, header=nil)
  server='https://'+server+':'+port.to_s+path
  uri = URI.parse(server)
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  http.verify_mode = OpenSSL::SSL::VERIFY_NONE
  request = Net::HTTP::Get.new(uri.request_uri, header)
  response = http.request(request)
  case response
    when Net::HTTPSuccess
      return JSON.parse response.body
    when Net::HTTPUnauthorized
      raise "Unauthorized"
    else
      raise response.message
  end
end

# Do a HTTP Post.
def doPOST(server, port, path, postData, header=nil)
  server='https://'+server+':'+port.to_s+path
  uri = URI.parse(server)
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  http.verify_mode = OpenSSL::SSL::VERIFY_NONE
  request = Net::HTTP::Post.new(uri.request_uri, header)
  request.body = postData.to_json
  response = http.request(request)
  case response
    when Net::HTTPSuccess
      return JSON.parse response.body
    when Net::HTTPConflict
      retVal = JSON.parse response.body
      raise retVal["messages"].to_s
    when Net::HTTPUnauthorized
      raise "Unauthorized"
    else
      raise response.body
  end
end

# Do a HTTP Delete.
def doDELETE(server, port, path, header=nil)
  server='https://'+server+':'+port.to_s+path
  uri = URI.parse(server)
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  http.verify_mode = OpenSSL::SSL::VERIFY_NONE
  request = Net::HTTP::Delete.new(uri.request_uri, header)
  response = http.request(request)
  case response
    when Net::HTTPSuccess
      return true
    when Net::HTTPUnauthorized
      raise "Unauthorized"
    else
      puts response.message
      raise response.message
  end
end

# Get authentication token to manage user's session.
def getAuthToken(transport)
  $json = doPOST(transport['server'], transport['port'], "/v1/tokens", {"data" => {"username" => transport['username'], "password" => transport['password']}})
  return $json['data']['session_token']
end

# Get the volume identifier from volume (LUN) name
def returnVolId(volname, transport)
  volumedetails = returnVolDetails(transport, volname)
  if volumedetails["data"].size != 0
    return volumedetails["data"][0]["id"]
  else
    return nil
  end
end

# Get the volume target name i.e. iSCSI Qualified Name (IQN) or
# the Fibre Channel World Wide Node Name (WWNN) from volume name.
def returnVolTargetName(volname, transport)
  volumedetails = returnVolDetails(transport, volname)
  if volumedetails["data"].size != 0
    return volumedetails["data"][0]["target_name"]
  else
    return nil
  end
end

# Get the volume Details from volume name.
def returnVolDetails(transport, volname)
  $token=Facter.value('token')
  volumedetails = doGET(transport['server'], transport['port'], "/v1/volumes/detail?name="+volname , {"X-Auth-Token" => $token})
  return volumedetails
end

# Returns all volumes details.
def returnAllVolumes(transport)
  $token=Facter.value('token')
  allVolumes = Array.new
  totalVolumes = doGET(transport['server'], transport['port'], "/v1/volumes", {"X-Auth-Token" => $token})

  startRow = 0
  endRow = totalVolumes["endRow"]
  totalRows = totalVolumes["totalRows"]

  # Do pagination
  begin
    volumes = doGET(transport['server'], transport['port'], "/v1/volumes/detail?startRow="+startRow.to_s, {"X-Auth-Token" => $token})["data"]
    volumes.each do |volume|
      allVolumes.push(volume)
    end
    startRow = startRow + volumes.size
  end while (allVolumes.size < totalRows)
  return allVolumes
end

# Returns Performance Policy Id from Performance Policy Human Readable Name.
def returnPerfPolicyId(transport, perfPolicyName)
  $token=Facter.value('token')
  allPerfPolicies = returnAllPerfPolicies(transport)
  allPerfPolicies.each do |policy|
    if perfPolicyName.eql? policy["name"]
      return policy["id"]
    end
  end
  return nil
end

# Returns all Performance Policy Names associated with different volumes.
def returnAllPerfPolicies(transport)
  $token=Facter.value('token')
  allPolicies = Array.new
  totalPolicies = doGET(transport['server'], transport['port'], "/v1/performance_policies", {"X-Auth-Token" => $token})

  startRow = 0
  endRow = totalPolicies["endRow"]
  totalRows = totalPolicies["totalRows"]

  # Do pagination
  begin
    policies = doGET(transport['server'], transport['port'], "/v1/performance_policies?startRow="+startRow.to_s, {"X-Auth-Token" => $token})["data"]
    policies.each do |policy|
      allPolicies.push(policy)
    end
    startRow = startRow + policies.size
  end while (allPolicies.size < totalRows)
  return allPolicies
end

# Returns Snapshot identifier from Snapshot name and Volume Name.
def returnSnapshotId(snapShotName, volName, transport)
  $token=Facter.value('token')
  allsnaps = returnAllSnapshots(volName, transport)
  allsnaps.each do |snap|
    if snapShotName.eql? snap["name"]
      return snap["id"]
    end
  end
  return nil
end

# Returns all snapshots of a volume.
def returnAllSnapshots(volName, transport)
  $token=Facter.value('token')
  allSnapshots = Array.new
  totalSnapshots = doGET(transport['server'], transport['port'], "/v1/snapshots?vol_name="+volName, {"X-Auth-Token" => $token})

  startRow = 0
  endRow = totalSnapshots["endRow"]
  totalRows = totalSnapshots["totalRows"]

  # Do pagination
  begin
    snapshots = doGET(transport['server'], transport['port'], "/v1/snapshots?vol_name="+volName+"&startRow="+startRow.to_s, {"X-Auth-Token" => $token})["data"]
    snapshots.each do |snapshot|
      allSnapshots.push(snapshot)
    end
    startRow = startRow + snapshots.size
  end while (allSnapshots.size < totalRows)
  return allSnapshots
end

# Returns all Initiator Groups details.
def returnAllinitiatorGroups(transport)
  $token=Facter.value('token')
  allInitiatorGroups = Array.new
  totalInitiatorGroups = doGET(transport['server'], transport['port'], "/v1/initiator_groups", {"X-Auth-Token" => $token})

  startRow = 0
  endRow = totalInitiatorGroups["endRow"]
  totalRows = totalInitiatorGroups["totalRows"]

  # Do pagination
  begin
    initiatorgroups = doGET(transport['server'], transport['port'], "/v1/initiator_groups/detail"+"?startRow="+startRow.to_s, {"X-Auth-Token" => $token})["data"]
    initiatorgroups.each do |initiatorgroup|
      allInitiatorGroups.push(initiatorgroup)
    end
    startRow = startRow + initiatorgroups.size
  end while (allInitiatorGroups.size < totalRows)
  return allInitiatorGroups
end

# Returns all Initiators details.
def returnAllinitiators(transport)
  $token=Facter.value('token')
  allInitiators = Array.new
  totalInitiators = doGET(transport['server'], transport['port'], "/v1/initiators", {"X-Auth-Token" => $token})

  startRow = 0
  endRow = totalInitiators["endRow"]
  totalRows = totalInitiators["totalRows"]

  # Do pagination
  begin
    initiators = doGET(transport['server'], transport['port'], "/v1/initiators/detail"+"?startRow="+startRow.to_s, {"X-Auth-Token" => $token})["data"]
    initiators.each do |initiator|
      allInitiators.push(initiator)
    end
    startRow = startRow + initiators.size
  end while (allInitiators.size < totalRows)
  return allInitiators
end

# Returns Identifier of Initiator Group.
def returnInitiatorGroupId(transport, initiatorgroupname)
  $token=Facter.value('token')
  allInitiatorGroups = returnAllinitiatorGroups(transport)
  allInitiatorGroups.each do |initiatorgroup|
    if initiatorgroup["name"] == initiatorgroupname
      return initiatorgroup["id"]
    end
  end

end

# Returns Identifier of all Initiator.
def returnInitiatorId(transport, iqn, ip_address, label=nil)
  $token=Facter.value('token')
  allInitiators = returnAllinitiators(transport)
  allInitiators.each do |initiator|
    if (initiator["iqn"] == iqn) || (initiator["ip_address"] == ip_address) || (initiator["label"] == label)
        return initiator["id"]
  end
  end
end

# Returns all Subnets.
def returnAllSubnets(transport)
  $token=Facter.value('token')
  allSubnets = Array.new
  totalSubnets = doGET(transport['server'], transport['port'], "/v1/subnets", {"X-Auth-Token" => $token})
  startRow = 0
  endRow = totalSubnets["endRow"]
  totalRows = totalSubnets["totalRows"]

  # Do pagination
  begin
    subnets = doGET(transport['server'], transport['port'], "/v1/subnets"+"?startRow="+startRow.to_s, {"X-Auth-Token" => $token})["data"]
    subnets.each do |subnet|
      allSubnets.push(subnet)
    end
    startRow = startRow + subnets.size
  end while (allSubnets.size < totalRows)
  return allSubnets
end

# Returns Identifier of CHAP User (Challenge-Response Handshake Authentication Protocol) using CHAP name.
def returnChapIdFromName(transport, chap_name)
  $token=Facter.value('token')
  $resp = doGET(transport['server'], transport['port'], "/v1/chap_users/detail"+"?name="+chap_name.to_s, {"X-Auth-Token" => $token})
  if $resp['data'].size > 0
    return $resp['data'][0]['id']
  else
    false
  end
end

# Get the access control record details from volume identifier.
def returnACRDetails(transport, volid)
  $token=Facter.value('token')
  acrdetails = doGET(transport['server'], transport['port'], "/v1/access_control_records/detail?vol_id="+volid.to_s , {"X-Auth-Token" => $token})
  return acrdetails['data']
end
