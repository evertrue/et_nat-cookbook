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

  describe file '/etc/nat_monitor.yml' do
    describe '#content' do
      subject { super().content }
      it { is_expected.to include 'mocking: true' }
      it { is_expected.to include 'route_table_id: rtb-a1b2c3d4' }
      it { is_expected.to include 'run: http://example.com/run' }
      it { is_expected.to include 'complete: http://example.com/complete' }
      it { is_expected.to include 'fail: http://example.com/fail' }
    end
  end
end
