module Terraforming
  module Resource
    class VPNGateway
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
        apply_template(@client, "tf/vpn_gateway")
      end

      def tfstate
        vpn_gateways.inject({}) do |resources, vpn_gateway|
          next resources if vpn_gateway.vpc_attachments.empty?

          attributes = {
            "id"     => vpn_gateway.vpn_gateway_id,
            "vpc_id" => vpn_gateway.vpc_attachments[0].vpc_id,
            "availability_zone" => vpn_gateway.availability_zone,
            "tags.#" => vpn_gateway.tags.length.to_s,
          }
          resources["aws_vpn_gateway.#{module_name_of(vpn_gateway)}"] = {
            "type" => "aws_vpn_gateway",
            "primary" => {
              "id"         => vpn_gateway.vpn_gateway_id,
              "attributes" => attributes
            }
          }

          resources
        end
      end

      private

      def vpn_gateways
        @client.describe_vpn_gateways({filters: @filters}).map(&:vpn_gateways).flatten
      end

      def module_name_of(vpn_gateway)
        normalize_module_name(name_from_tag(vpn_gateway, vpn_gateway.vpn_gateway_id))
      end
    end
  end
end
