Puppet::Type.newtype(:host_init) do
  @doc = "Prepare Host Facts"

  ensurable
  newparam(:name) do
    desc "Name of Resource"
  end
  newparam(:transport) do
    desc "Transport to connect to array"
  end

end
