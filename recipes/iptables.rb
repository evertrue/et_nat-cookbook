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

cookbook_file '/etc/iptables.rules' do
  source 'iptables.rules'
  owner  'root'
  group  'root'
  mode   0644
end

execute 'iptables-restore' do
  command '/sbin/iptables-restore < /etc/iptables.rules'
end

cookbook_file '/etc/network/if-pre-up.d/iptables_load' do
  source 'iptables_load'
  mode   0755
end

if node['ec2']['network_interfaces_macs'] # keeps this from running on Vagrant
  if node['nat']['yaml']['aws_access_key_id']
    conn_opts = {
      aws_access_key_id: node['nat']['yaml']['aws_access_key_id'],
      aws_secret_access_key: node['nat']['yaml']['aws_secret_access_key']
    }
  else
    conn_opts = { use_iam_profile: true }
  end

  if node['nat']['yaml']['aws_url']
    conn_opts[:endpoint] = node['nat']['yaml']['aws_url']
  end

  ::EverTrue::EtNat::Helpers.disable_source_dest_check(
    node['ec2']['network_interfaces_macs'].values[0]['interface_id'],
    conn_opts
  )
end
