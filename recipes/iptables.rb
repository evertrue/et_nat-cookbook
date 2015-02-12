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
