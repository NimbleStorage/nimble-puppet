Puppet::Type.newtype(:nimble_initiatorgroup) do
  @doc = "Manages Nimble Array initiator groups"

    ensurable
    newparam(:name) do
        desc "Name of initiator group. String of up to 64 alphanumeric characters, - and . and : are allowed after first character. Example: 'myobject-5'."
        isnamevar
    end
    newparam(:transport) do
    	desc "Credentials to connect to array"
    end
    newparam(:description) do
        desc "Text description of initiator group. Default: ''. String of up to 255 printable ASCII characters. Example: '99.9999% availability'."
    end
    newparam(:access_protocol) do
        desc "Initiator group access protocol. Possible values: 'iscsi', 'fc'."
    end
    newparam(:target_subnets) do
        desc "List of target subnet labels. If specified, discovery and access to volumes will be restricted to the specified subnets. Default: '[]'. List of target subnet tables."
    end
    newparam(:host_type) do
      desc "Available options are auto (default) and hpux. This attribute will be applied to all the initiators in the initiator group.  String of up to 64 alphanumeric characters, - and . and : are allowed after first character. Example: 'myobject-5'."
    end
    newparam(:app_uuid) do
      desc "Application identifier of initiator group. String of up to 255 alphanumeric characters, hyphen, colon, dot and underscore are allowed. Example: 'rfc4122.943f7dc1-5853-497c-b530-f689ccf1bf18'."
    end

=begin
    newparam(:iscsi_initiators) do
    	desc "List of iSCSI initiators. When create/update iscsi_initiators, either iqn or ip_address is always required with label. List of iSCSI initiators."
    end
    newparam(:fc_initiators) do
    	desc "List of FC initiators. When create/update fc_initiators, wwpn is required. List of Fibre Channel initiators."
    end
=end

end
