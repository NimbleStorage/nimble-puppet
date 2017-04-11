require 'fileutils'
require "net/https"
require "uri"
require "nimblerest"
require "facter"

Puppet::Type.type(:nimble_chap).provide(:nimble_chap) do
  desc "Work on Nimble Array CHAP Accounts"

  def create
    $token=Facter.value('token')
    requestedParams = Hash.new
    requestedParams[:password] = resource[:password]
    requestedParams[:name] = resource[:username]
    puts "Creating New CHAP Account -> #{resource[:username]}"
    doPOST(resource[:transport]['server'], resource[:transport]['port'], "/v1/chap_users", {"data" => requestedParams}, {"X-Auth-Token" => $token})
  end

  def destroy
    $token=Facter.value('token')
    requestedParams = Hash.new
    requestedParams[:name] = resource[:username]
    id = returnChapIdFromName(resource[:transport], requestedParams[:name])
    puts "Deleting CHAP Account -> #{resource[:username]}"
    doDELETE(resource[:transport]['server'], resource[:transport]['port'], "/v1/chap_users/"+id, {"X-Auth-Token" => $token})
  end

  def exists?
    if resource[:ensure].to_s == "absent"
      chapUser = returnChapIdFromName(resource[:transport], resource[:username])
      if chapUser
        return true
      end
    end
    chapUser = returnChapIdFromName(resource[:transport], resource[:username])
    if chapUser
      return true
    end
    return false
  end
end
