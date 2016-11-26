require 'spec_helper'
describe 'nimblestorage' do
  context 'with default values for all parameters' do
    it { should contain_class('nimblestorage') }
  end
end
