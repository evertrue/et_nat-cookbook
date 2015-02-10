#
# Cookbook Name:: et_nat
# Recipe:: default
#
# Copyright (C) 2013 EverTrue, Inc.
#
# All rights reserved - Do Not Redistribute
#
# rubocop: disable SingleSpaceBeforeFirstArg
include_recipe 'et_fog'

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

nat_instances = search(:node,
                       'recipes:et_nat AND ' \
                       "chef_environment:#{node.chef_environment} AND " \
                       "nat_cluster_name:#{node['nat']['cluster_name']}")

if nat_instances.count > 2
  # Only try to set up a heartbeat if we're actually in a cluster
  gem_package 'net-ping'
  gem_package 'unf'
  gem_package 'fog'
  gem_package 'nat-monitor'

  log 'Other instances found.  Setting up the NAT Monitor.' do
    level :info
  end

  node.set['nat']['yaml']['nodes'] =
    nat_instances.each_with_object({}) do |n, m|
      fail "no ec2 attribute found: #{n.inspect}" unless n['ec2']
      m[n['ec2']['instance_id']] = n['ipaddress']
    end

  if node['nat']['route_table']
    node.set['nat']['yaml']['route_table'] = node['nat']['route_table']
  else
    node.set['nat']['yaml']['route_table'] =
      ::EverTrue::EtNat::Helpers.nat_route_table_id(
        node.chef_environment,
        (if node['nat']['yaml']['aws_url']
           { endpoint: node['nat']['yaml']['aws_url'] }
         else
           {}
         end)
      )
  end

  file '/etc/nat_monitor.yml' do
    owner  'root'
    group  'root'
    mode   0644
    content JSON.parse(node['nat']['yaml'].to_json).to_yaml
  end

  cron 'nat-monitor' do
    minute '@reboot'
    hour ''
    day ''
    month ''
    weekday ''
    command '/opt/chef/embedded/bin/ruby /opt/chef/embedded/bin/nat-monitor'
  end
end
