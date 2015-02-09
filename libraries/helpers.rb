module EverTrue
  module EtNat
    module Helpers
      def self.nat_route_table_id(env, conn_opts = {})
        require 'fog'

        conn_opts.merge!(aws_access_key_id: 'AWS_ACCESS_KEY_ID',
                         aws_secret_access_key: 'AWS_SECRET_ACCESS_KEY')

        Chef::Log.debug("Using conn_opts: #{conn_opts.inspect}")

        connection = Fog::Compute::AWS.new(conn_opts)

        vpc_routes = connection.route_tables.select do |rt|
          rt.vpc_id == connection.vpcs.find { |v| v.tags['Env'] == env }.id
        end

        table = vpc_routes.select do |vr|
          !vr.routes.select do |r|
            r['destinationCidrBlock'] == '0.0.0.0/0' &&
            r['gatewayId'].nil? &&
            !r['instanceId'].nil? &&
            r['state'] == 'active'
          end.empty?
        end
        fail 'Found more than one viable route table' if table.count > 1
        table
      end
    end
  end
end
