Puppet::Type.newtype(:nimble_volume) do
  @doc = "Manages Nimble Array Volume"

    ensurable
    newparam(:name) do
        desc "Name of the volume. String of of up to 215 alphanumeric, hyphenated, colon, or period separated characters but cannot begin with hyphen, colon or period. This type is used for volumes, snapshots and snapshot_collections object sets."
        isnamevar
    end
    newparam(:online, :boolean => :true) do
        desc "Online state of volume, available for host initiators to establish connections. Possible values: 'true', 'false'."
        newvalues(:true, :false)
        defaultto(:true)
    end
    newparam(:transport) do
    	desc "Credentials to connect to array"
    end
    newparam(:size) do
        desc "Volume size. Can be specified in one of the following size units: [mgt]. Size is required for creating a volume but not for cloning an existing volume. Unsigned 64-bit integer. Example: 1234."

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
        desc "Forcibly offline, reduce size or change read-only status a volume. Possible values: 'true', 'false'."
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
        desc "Limit for the volume as a percentage of volume size. Percentage as integer from 0 to 100."
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
        desc "External management agent type. Default: 'none'. Possible values: 'smis', 'vvol', 'openstack', 'openstackv2'."
    end
    newparam(:config) do
      desc "ISCSI Config"
    end
    newparam(:mp) do
      desc "Multipath configs"
    end
    newparam(:snap_limit_percent) do
      desc "Limit for the space used by the volume's snapshots, expressed either as a percentage of the volume's size or as -1 to indicate that there is no limit. If this option is not specified when the volume is created, the group's default snapshot limit will be used. Signed 64-bit integer. Example: -1234."
    end
    newparam(:clone) do
        desc "Whether this volume is a clone. Use this attribute in combination with name and base_snap_id to create a clone by setting clone = true. Possible values: 'true', 'false'."
    end
    newparam(:limit_iops) do
        desc "IOPS limit for this volume.If -1, then the volume has no IOPS limit.  If limit_iops is not specified while creating a clone, IOPS limit of parent volume will be used as limit. IOPS limit should be in range [256, 4294967294] or -1 for unlimited. If both limit_iops and limit_mbps are specified, limit_mbps must not be hit before limit_iops. In other words, IOPS and MBPS limits should honor limit_iops _ampersand_amp;lt;= ((limit_mbps MB/s * 2^20 B/MB) / block_size B). Signed 64-bit integer. Example: -1234."
    end
    newparam(:limit_mbps) do
        desc "Throughput limit for this volume in MB/s. If limit_mbps is not specified when a volume is created, or if limit_mbps is set to -1, then the volume has no MBPS limit. MBPS limit should be in range [1, 4294967294] or -1 for unlimited. If both limit_iops and limit_mbps are specified, limit_mbps must not be hit before limit_iops. In other words, IOPS and MBPS limits should honor limit_iops _ampersand_amp;lt;= ((limit_mbps MB/s * 2^20 B/MB) / block_size B). Signed 64-bit integer. Example: -1234."
    end
    newparam(:dedupe_enabled) do
        desc "Indicate whether dedupe is enabled. Possible values: 'true', 'false'."
    end
  newparam(:vol_coll)do
    desc "Volume Collection to join"
  end

  newparam(:base_snap_name) do
    desc "Base snapshot ID. This attribute is required together with name and clone when cloning a volume with the create operation. A 42 digit hexadecimal number. Example: '2a0df0fe6f7dc7bb16000000000000000000004817'."
  end

  newparam(:restore_from) do
    desc "Base snapshot ID. This attribute is required together with name and clone when cloning a volume with the create operation. A 42 digit hexadecimal number. Example: '2a0df0fe6f7dc7bb16000000000000000000004817'."
  end

=begin
    newparam(:owned_by_group_id) do
      desc "ID of group that currently owns the volume. A 42 digit hexadecimal number. Example: '2a0df0fe6f7dc7bb16000000000000000000004817'."
    end
    newparam(:dest_pool_id) do
        desc "ID of the destination pool where the volume is moving to. A 42 digit hexadecimal number. Example: '2a0df0fe6f7dc7bb16000000000000000000004817'."
    end
    newparam(:metadata) do
        desc "Key-value pairs that augment a volume's attributes. "
    end
    newparam(:app_uuid) do
        desc "Application identifier of volume. String of up to 255 alphanumeric characters, hyphen, colon, dot and underscore are allowed. Example: 'rfc4122.943f7dc1-5853-497c-b530-f689ccf1bf18'."
    end
    newparam(:folder_id) do
        desc "ID of the folder holding this volume. An optional NsObjectID. A 42 digit hexadecimal number or the empty string. Example: '1234123412341234123412341234123412341234cd' or ''."
    end
=end

end
