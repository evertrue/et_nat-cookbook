# Encoding: utf-8
require 'spec_helper'
require 'fog'
require 'net/http'

describe 'et_nat::default' do
  describe 'instance settings' do
    before do
      network_interface_mac = Net::HTTP.get(
        '169.254.169.254',
        '/latest/meta-data/network/interfaces/macs/'
      )
      network_interface_id = Net::HTTP.get(
        '169.254.169.254',
        '/latest/meta-data/network/interfaces/macs/' \
        "#{network_interface_mac}interface-id/")
      connection = Fog::Compute::AWS.new(use_iam_profile: true)
      @eni = connection.network_interfaces.get(network_interface_id)
    end

    it 'should have source-dest check disabled' do
      expect(@eni.source_dest_check).to be false
    end
  end

  describe 'iptables' do
    describe command('/sbin/iptables -t nat --list') do
      it 'contains MASQUERADE rule' do
        expect(subject.stdout).to match(/^MASQUERADE/)
      end
    end
  end
end
