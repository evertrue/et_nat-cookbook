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
  source 'iptables-save'
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
