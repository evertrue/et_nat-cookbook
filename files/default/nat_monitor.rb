module EtTools
  class NatMonitor
    require 'net/http'
    require 'net/ping'
    require 'fog'
    require 'yaml'

    def connection
      @connection ||= begin
        connection = Fog::Compute.new(
          :provider => 'AWS',
          :aws_access_key_id => 'AWS_ACCESS_KEY_ID',
          :aws_secret_access_key => 'AWS_SECRET_ACCESS_KEY'
        )
      end
    end

    def instance_id
      @instance_id ||= begin
        instance_id = Net::HTTP.get(
          '169.254.169.254',
          '/latest/meta-data/instance-id'
        )
      end
    end

    def other_gateway_ip( other_gateway_id )
      @other_gateway_ip ||= begin
        # This makes sure we always find the FIRST network interface
        # for our gateway instance.  Important because sometimes
        # private_ip_address sometimes finds IPs
        other_gateway_ip = connection.network_interfaces.select do |ni|
          ni.attachment['instanceId'] &&
          ni.attachment['instanceId'] == other_gateway_id &&
          ni.attachment['deviceIndex'] == '0'
        end.first.private_ip_address
      end
    end

    def output( message )
      puts message
    end

    def route_ours?
      connection.describe_route_tables.body['routeTableSet'].select { |rt| rt['routeTableId'] == @route_table }.first['routeSet'].select { |r| r['destinationCidrBlock'] == '0.0.0.0/0' }.first['instanceId'] == instance_id
    end

    def steal_route
      unless route_ours?
        output 'Stealing route 0.0.0.0/0 on route table ' + @route_table
        connection.replace_route(
          @route_table,
          '0.0.0.0/0',
          @other_gateway_id
        )
      else
        output 'We already control this route.  Not stealing it again.'
      end
    end

    def other_instance_stopped?
      connection.servers.get( @other_gateway_id ).state == 'stopped'
    end

    def start_other_instance
      output "Starting other instance (#{@other_gateway_id})"
      connection.servers.get( @other_gateway_id ).start
      sleep @wait_for_instance_start
      if connection.servers.get( @other_gateway_id ).state != 'running'
        output 'WARNING: Other instance still not running after ' +
          @wait_for_instance_start + ' seconds.  Giving up.'
      end
    end

    def stonith
      output "Stopping other instance (#{@other_gateway_id})"
      connection.servers.get( @other_gateway_id ).stop
      sleep @wait_for_instance_stop
      if ! other_instance_stopped?
        output "WARNING: Other instance did not stop after " +
          "#{@wait_for_instance_stop} seconds.  Giving up."
      end
    end

    def heartbeat

      pgw = Net::Ping::External.new( @other_gateway_ip )
      pgw.timeout = 1

      output 'Starting heartbeat...'

      while true

        if ! pgw.ping?
          steal_route
          if other_instance_stopped?
            start_other_instance
          else
            stonith
          end
        else
          sleep @wait_between_pings
        end

      end

    end

    def initialize(conf_file = nil)
      conf = YAML.load_file(conf_file || '/etc/nat_monitor.yml')

      @other_gateway_id = conf['other_gateway_id']
      @route_table = conf['route_table']

      @pings = conf['pings'] || 3
      @ping_timeout = conf['ping_timeout'] || 1
      @wait_between_pings = conf['wait_between_pings'] || 2
      @wait_for_instance_stop = conf['wait_for_instance_stop'] || 60
      @wait_for_instance_start = conf['wait_for_instance_start'] || 60
    end

    def run
      output 'Starting NAT Monitor'

      if ! route_exists?
        raise "The specified routing table #{route_table} does not exist."
      end

      steal_route
      heartbeat
    end
  end
end

nm = EtTools::NatMonitor.new(ARGV[0])
nm.run
