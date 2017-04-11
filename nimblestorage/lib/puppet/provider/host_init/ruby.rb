require 'fileutils'
require "net/https"
require "uri"
require "nimblerest"
require "facter"
require 'puppet/util'

Puppet::Type.type(:host_init).provide(:host_init) do
  desc "Fix all Global facts"

  def create
    puts "Fact's are being picked up"
    unless Facter.value(:token)
      $token=getAuthToken(resource[:transport])
      Facter.add('token') do
        setcode do
          $token
        end
      end
    end
    unless Facter.value(:iscsi_initiator)
      Facter.add('iscsi_initiator') do
        setcode do
          if File.exist? "/etc/iscsi/initiatorname.iscsi"
            Facter::Core::Execution.exec('/usr/bin/tail -1 /etc/iscsi/initiatorname.iscsi | /usr/bin/cut -d "=" -f2')
          else
            false
          end
        end
      end
    end
    #puts Facter.value(:iscsi_initiator)
  end


  def destroy

  end

  def exists?
    if resource[:ensure].to_s == "absent"
      return true
    end
    if (Facter.value(:iscsi_initiator)) && (Facter.value(:token))
      return true
    end
    return false
  end
end
