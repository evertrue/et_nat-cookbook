#
# Cookbook Name:: et_nat
# Recipe:: default
#
# Copyright (C) 2013 EverTrue, Inc.
#
# All rights reserved - Do Not Redistribute
#

execute 'sysctl-nat' do
  command 'sysctl -p /etc/sysctl.d/nat.conf'
  action  :nothing
end

cookbook_file '/etc/sysctl.d/nat.conf' do
  source 'sysctl-nat.conf'
  owner  'root'
  group  'root'
  mode   0644
  notifies :run, 'execute[sysctl-nat]'
end

execute 'iptables-masquerade' do
  command '/sbin/iptables -t nat -A POSTROUTING -o eth0 -s 0.0.0.0/0 ' \
          '-j MASQUERADE'
  action  :run
  not_if  "/sbin/iptables -t nat --list | grep -q '^MASQUERADE'"
end

cookbook_file '/etc/iptables.rules' do
  source 'iptables-save'
  owner  'root'
  group  'root'
  mode   0644
end

nat_instances = search(:node, 'recipes:et_nat AND chef_environment:' + node.chef_environment)

if nat_instances.count > 1
  # Only try to set up a heartbeat if we're actually in a
  # primary/failover cluster
  gem_package 'net_ping'
  gem_package 'unf'
  gem_package 'fog'

  log 'Other instances found.  Setting up the NAT Monitor.' do
    level :info
  end

  template '/etc/nat_monitor.yml' do
    source 'nat_monitor.yml.erb'
    owner  'root'
    group  'root'
    mode   0644
    variables(:other_gateway_id => other_gateway_id)
  end

  cookbook_file '/usr/bin/nat_monitor.rb' do
    source 'nat_monitor.rb'
    owner  'root'
    group  'root'
    mode   0755
  end

  cron 'nat_monitor' do
    minute  '@reboot'
    command 'ruby /usr/bin/nat_monitor.rb'
  end
end
