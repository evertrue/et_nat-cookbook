# Encoding: utf-8
require 'spec_helper'

describe 'iptables' do
  describe command('/sbin/iptables -t nat --list') do
    it 'contains MASQUERADE rule' do
      expect(subject.stdout).to match(/^MASQUERADE/)
    end
  end
end
