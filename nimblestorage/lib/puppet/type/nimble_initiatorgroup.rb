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
end
