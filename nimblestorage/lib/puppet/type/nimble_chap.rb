Puppet::Type.newtype(:nimble_chap) do
  @doc = "Manages Nimble CHAP Accounts"

  ensurable
  newparam(:name) do
    desc "Name of Resource"
  end
  newparam(:username) do
    desc "Name of CHAP User"
  end
  newparam(:transport) do
    desc "Credentials to connect to array"
  end
  newparam(:password) do
    desc "CHAP User Password"
  end
  newparam(:description) do
    desc "Text description of CHAP user. String of up to 255 printable ASCII characters. Example: '99.9999% availability'."
  end
end
