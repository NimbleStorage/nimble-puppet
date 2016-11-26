Puppet::Type.newtype(:nimble_volume) do
  @doc = "Manages Nimble Array Volume"

    ensurable
    newparam(:name) do
        desc "Name of the volume. String of of up to 215 alphanumeric, hyphenated, colon, or period separated characters but cannot begin with hyphen, colon or period. This type is used for volumes, snapshots and snapshot_collections object sets.	"
        isnamevar
    end
    newparam(:online, :boolean => :true) do
        desc "Online state of volume, available for host initiators to establish connections. Default: 'true'. Possible values: 'true', 'false'.	"
        newvalues(:true, :false)
        defaultto(:true)
    end
    newparam(:transport) do
    	desc "Credentials to connect to array"
    end
    newparam(:size) do
        desc "Volume size. Can be specified in one of the following size units: [mgt]."
	    
	    validate do |value|
    	  raise ArgumentError, "Value must be a Non-Zero Integer and specify a size unit. [mgt]" unless value =~ /^\d+[mgt]{1}$/
    	end

    	munge do |value|
      	if value =~ /\d+[mgt]/
        	# Convert from size unit to bytes
        	if value.include?('t')
          		value = value.gsub(/t/, '').to_i*1024*1024
        	elsif value.include?('g')
          		value = value.gsub(/g/, '').to_i*1024
        	elsif value.include?('m')
          		value = value.gsub(/m/, '').to_i
        	end
        	value
        end
    	end
    end
    
    newparam(:force, :boolean => :false) do
        desc "Force the volume operation"
        newvalues(:true, :false)
        defaultto(:false)
    end
    newparam(:description) do
        desc "Text description of volume. Default: ''. String of up to 255 printable ASCII characters. Example: '99.9999% availability'.	"
    end
    newparam(:block_size) do
        desc "Size in bytes of blocks in the volume. Default: 4096. Unsigned 64-bit integer. Example: '1234'.	"
        validate do |value|
			raise ArgumentError, 'block_size must be an non-Zero Integer' unless value.to_i  > 0
		end
    end
    newparam(:perfpolicy) do
        desc "Name of performance policy. After creating a volume, performance policy for the volume can only be changed to another performance policy with same block size."
    end
    newparam(:reserve) do
        desc "Amount of space to reserve for this volume as a percentage of volume size. Default: (default volume reservation set on the group, typically 0). Percentage as integer from 0 to 100.	"
    end
    newparam(:warn_level) do
        desc "Threshold for available space as a percentage of volume size below which an alert is raised. If this option is not specified, array default volume warn level setting is used to decide the warning level for this volume. Default: (default volume warning level set on the group, typically 80). Percentage as integer from 0 to 100.	"
    end
    newparam(:limit) do
        desc "Limit for the volume as a percentage of volume size. Default: (default volume limit set on group, typically 100). Percentage as integer from 0 to 100.	"
    end
    newparam(:snap_reserve) do
        desc "Amount of space to reserve for snapshots of this volume as a percentage of volume size. Default: (default snapshot reserve set on the group, typically 0). Unsigned 64-bit integer. Example: 1234.	"
    end
    newparam(:snap_warn_level) do
        desc "Threshold for available space as a percentage of volume size below which an alert is raised. Default: (default snapshot warning level set on the group, typically 0). Unsigned 64-bit integer. Example: 1234.	"
    end
    newparam(:snap_limit) do
        desc "Limit for snapshots of the volume as a percentage of volume size. If this option is not specified, default snapshot limit set on the group is used to specify no limit for snapshot data. Default: 9223372036854775807. Unsigned 64-bit integer. Example: 1234.	"
    end
    newparam(:multi_initiator) do
        desc "This indicates whether volume and its snapshots are multi-initiator accessible. This attribute applies only to volumes and snapshots available to iSCSI initiators. Default: 'false'. Possible values: 'true', 'false'.	"
    end
    newparam(:pool_id) do
        desc "Identifier associated with the pool in the storage pool table. Default: (ID of the 'default' pool). A 42 digit hexadecimal number. Example: '2a0df0fe6f7dc7bb16000000000000000000004817'.	"
    end
    newparam(:read_only) do
        desc "Volume is read-only. Default: 'false'. Possible values: 'true', 'false'.	"
    end
    newparam(:cache_pinned) do
        desc "If set to true, all the contents of this volume are kept in flash cache. This provides for consistent performance guarantees for all types of workloads. The amount of flash needed to pin the volume is equal to the limit for the volume. Default: 'false'. Possible values: 'true', 'false'.	"
    end
    newparam(:encryption_cipher) do
        desc "The encryption cipher of the volume. Default: 'none'. Possible values: 'none', 'aes_256_xts'.	"
    end
    newparam(:agent_type) do
        desc "External management agent type. Default: 'none'. Possible values: 'smis', 'none', 'all', 'vvol'.	"
    end
end
