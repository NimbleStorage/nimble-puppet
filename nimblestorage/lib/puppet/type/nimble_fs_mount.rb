Puppet::Type.newtype(:nimble_fs_mount) do
  @doc = "Manages Nimble Array initiators"

    ensurable
  newparam(:name) do
    desc "Name of initiator Group"
  end
  newparam(:target_vol) do
    desc "Name of initiator Group"
  end
  newparam(:mount_point) do
    desc "Name of initiator Group"
  end
  newparam(:transport) do
    desc "Name of initiator Group"
  end
  newparam(:fs) do
    desc "Name of initiator Group"
  end
  newparam(:mp) do
    desc "Name of initiator Group"
  end
  newparam(:label) do
    desc "Name of initiator Group"
  end
  newparam(:config) do
    desc "ISCSI Config"
  end
end
