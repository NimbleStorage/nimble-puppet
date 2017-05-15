Puppet::Type.newtype(:nimble_protection_template) do
  @doc = "Manages Nimble protection template"

    ensurable
    newparam(:name) do
        desc "User provided identifier. String of up to 64 alphanumeric characters, - and . and : are allowed after first character. Example: 'myobject-5'."
        isnamevar
    end

    newparam(:transport) do
    	desc "Credentials to connect to array"
    end

    newparam(:schedule_list) do
        desc "List of schedules for this protection policy. List of snapshot schedules associated with a volume collection or protection template."
    end
    newparam(:description) do
        desc "Text description of protection template. String of up to 255 printable ASCII characters. Example: '99.9999% availability'."
    end

end
