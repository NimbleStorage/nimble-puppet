Puppet::Type.newtype(:nimble_initiator) do
  @doc = "Manages Nimble Array initiators"

    ensurable
    newparam(:name) do
        desc "Name of initiator"
        #isnamevar
    end
    newparam(:transport) do
    	desc "Credentials to connect to array"
    end
    newparam(:label) do
        desc "Unique Identifier of the iSCSI initiator. Label is required when creating iSCSI initiator. String of up to 64 alphanumeric characters, - and . and : are allowed after first character. Example: myobject-5."
    end
    newparam(:access_protocol) do
        desc "Initiator group access protocol. Possible values: iscsi, fc."
    end
    newparam(:iqn) do
        desc "IQN name of the iSCSI initiator. Each initiator IQN name must have an associated IP address specified using the ip_address attribute. You can choose not to enter the IP address for an initiator if you prefer not to authenticate using both name and IP address, in this case the IP address will be returned as *. Alphanumeric, hyphenated, colon or period separated string of up to 255 characters. Example: iqn.2007-11.com.storage:zmytestvol1-v0df0fe6f7dc7bb16.0000016b.70374579."
    end
    newparam(:ip_address) do
        desc "IP address of the iSCSI initiator. Each initiator IP address must have an associated name specified using name attribute. You can choose not to enter the name for an initiator if you prefer not to authenticate using both name and IP address, in this case the IQN name will be returned as *. String of four period-separated numbers, each in range [0,255]. Example: 128.0.0.1 or *."
    end
    newparam(:alias) do
      desc "Alias of the Fibre Channel initiator. Maximum alias length is 32 characters. Each initiator alias must have an associated WWPN specified using the wwpn attribute. You can choose not to enter the WWPN for an initiator when using previously saved initiator alias. String of up to 32 alphanumeric characters, or one of $^-_.: cannot begin with non-alphanumeric character. Example: my_initiator-4."
    end
    newparam(:wwpn) do
      desc "WWPN (World Wide Port Name) of the Fibre Channel initiator. WWPN is required when creating a Fibre Channel initiator. Each initiator WWPN can have an associated alias specified using the alias attribute. You can choose not to enter the alias for an initiator if you prefer not to assign an initiator alias. Eight bytes expressed in hex separated by colons. Example: af:32:f1:20:bc:ba:43:1a"
    end
end
