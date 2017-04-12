Puppet::Type.newtype(:nimble_acr) do
  @doc = "Manages Nimble Array Volume Access Control Records"

  ensurable
  newparam(:name) do
    desc "Name of the Resource"
    isnamevar
  end
  newparam(:apply_to) do
    desc "Type of object this access control record applies to. Default: 'both'. Possible values: 'volume', 'snapshot', 'both', 'pe', 'vvol_volume', 'vvol_snapshot'."
  end

  newparam(:volume_name) do
    desc "Identifier for the volume this access control record applies to."
  end

  newparam(:chap_user) do
    desc "Identifier for the CHAP user. Default: ''; which allows any CHAP user. "
  end

  newparam(:initiator_group) do
    desc "Identifier for the initiator group. Default: ''; which allows any initiators."
  end

  newparam(:lun) do
    desc "LUN (Logical Unit Number) to associate with this volume for access by both iSCSI and Fibre Channel initiator group. Valid LUNs are in the 0-2047 range. If not specified, system will generate one for you."
  end

  newparam(:transport) do
    desc "Credentials to connect to array"
  end

end
