Puppet::Type.newtype(:nimble_snapshot) do
  @doc = "Manages Nimble Array Snapshots"

    ensurable
    newparam(:name) do
        desc "Name of snapshot. String of of up to 215 alphanumeric, hyphenated, colon, or period separated characters but cannot begin with hyphen, colon or period. This type is used for volumes, snapshots and snapshot_collections object sets."
        isnamevar
    end
    newparam(:transport) do
      desc "The credentials to connect to array"
    end
    newparam(:description) do
      desc "Text description of snapshot. Default: ''. String of up to 255 printable ASCII characters. Example: '99.9999% availability'."
    end
    newparam(:vol_name) do
      desc "Name of the Volume for which You need snapshot"
    end
    newparam(:online, :boolean => :false) do
      desc "Online state for a snapshot means it could be mounted for data restore. Default: false. Possible values: true, false."
      newvalues(:true, :false)
      defaultto(:false)
    end
    newparam(:writable, :boolean => :false) do
      desc "Allow snapshot to be writable. Default: false. Possible values: true, false."
      newvalues(:true, :false)
      defaultto(:false)
    end
end
