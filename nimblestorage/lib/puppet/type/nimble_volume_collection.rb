Puppet::Type.newtype(:nimble_volume_collection) do
  @doc = "Manages Nimble Volume collection"

  ensurable

  newparam(:name) do
    desc "Name of volume collection. String of up to 64 alphanumeric characters, - and . and : are allowed after first character. Example: 'myobject-5'"
    isnamevar
  end

  newparam(:transport) do
    desc "Credentials to connect to array"
  end

  newparam(:prottmpl_name) do
    desc "Identifier of the protection template whose attributes will be used to create this volume collection. This attribute is only used for input when creating a volume collection and is not outputed. A 42 digit hexadecimal number. Example: '2a0df0fe6f7dc7bb16000000000000000000004817'"
  end

  newparam(:description) do
    desc "Text description of volume collection. String of up to 255 printable ASCII characters. Example: '99.9999% availability'."
  end

end
