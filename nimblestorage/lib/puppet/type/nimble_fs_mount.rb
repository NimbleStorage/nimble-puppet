Puppet::Type.newtype(:nimble_fs_mount) do
  @doc = "Manages Nimble Array initiators"

    ensurable
  newparam(:name) do
    desc "Name of resource"
  end
  newparam(:target_vol) do
    desc "Volume to be mounted"
  end
  newparam(:mount_point) do
    desc "Path where volume gets mounted"
  end
  newparam(:transport) do
    desc "Credentials to connect to array"
  end
  newparam(:fs) do
    desc "Type of filesystem"
  end
  newparam(:mp) do
    desc "Multipath config"
  end
  newparam(:label) do
    desc "Volume label"
  end
  newparam(:config) do
    desc "ISCSI Config"
  end
end
