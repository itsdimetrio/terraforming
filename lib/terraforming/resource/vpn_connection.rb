module Terraforming
  module Resource
    class VPNConnection
      include Terraforming::Util

      def self.tf(client: Aws::EC2::Client.new, filters: [{}])
        self.new(client, filters).tf
      end

      def self.tfstate(client: Aws::EC2::Client.new, filters: [{}])
        self.new(client, filters).tfstate
      end

      def initialize(client, filters)
        @client = client
	@filters = filters
      end

      def tf
        apply_template(@client, "tf/vpn_connection")
      end

      def tfstate
        vpn_connections.inject({}) do |resources, vpn_connection|
          #next resources if vpn_connection.routes.empty?

          attributes = {
            "id"     => vpn_connection.vpn_connection_id,
            "tags.#" => vpn_connection.tags.length.to_s,
          }
          resources["aws_vpn_connection.#{module_name_of(vpn_connection)}"] = {
            "type" => "aws_vpn_connection",
            "primary" => {
              "id"         => vpn_connection.vpn_connection_id,
              "attributes" => attributes
            }
          }

          resources
        end
      end

      private

      def vpn_connections
        @client.describe_vpn_connections({filters: @filters}).map(&:vpn_connections).flatten
      end

      def module_name_of(vpn_connection)
        normalize_module_name(name_from_tag(vpn_connection, vpn_connection.vpn_connection_id))
      end
    end
  end
end
