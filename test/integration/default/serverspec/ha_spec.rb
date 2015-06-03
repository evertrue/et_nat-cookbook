require 'spec_helper'

describe 'et_nat::ha' do
  describe service('nat-monitor') do
    it { is_expected.to be_enabled }
    it { is_expected.to be_running.under('upstart') }
  end

  describe process('ruby') do
    it { is_expected.to be_running }
    its(:args) { should match(/nat-monitor/) }
  end
end
