Puppet::Type.newtype(:nimble_protection_template) do
  @doc = "Manages Nimble Array Volume"

    ensurable
    newparam(:name) do
        desc "Name of the volume. String of of up to 215 alphanumeric, hyphenated, colon, or period separated characters but cannot begin with hyphen, colon or period. This type is used for volumes, snapshots and snapshot_collections object sets."
        isnamevar
    end

    newparam(:transport) do
    	desc "Credentials to connect to array"
    end

    newparam(:schedule_list) do
        desc "Forcibly offline, reduce size or change read-only status a volume. Possible values: 'true', 'false'."
    end
    newparam(:description) do
        desc "Text description of volume. Default: ''. String of up to 255 printable ASCII characters. Example: '99.9999% availability'.	"
    end

end
