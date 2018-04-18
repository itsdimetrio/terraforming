require "spec_helper"

module Terraforming
  module Resource
    describe VPNConnection do
      let(:client) do
        Aws::EC2::Client.new(stub_responses: true)
      end

      let(:vpn_connections) do
        [
          {
            vpn_connection_id: "vgw-1234abcd",
            tags: [],
          },
          {
            vpn_connection_id: "vgw-5678efgh",
            tags: [
              {
                key: "Name",
                value: "test"
              }
            ]
          }
        ]
      end

      before do
        client.stub_responses(:describe_vpn_connections, vpn_connections: vpn_connections)
      end

      describe ".tf" do
        it "should generate tf" do
          expect(described_class.tf(client: client)).to eq <<-EOS
resource "aws_vpn_connection" "vgw-1234abcd" {
    tags {
    }
}

resource "aws_vpn_connection" "test" {
    tags {
        "Name" = "test"
    }
}

        EOS
        end
      end

      describe ".tfstate" do
        it "should generate tfstate" do
          expect(described_class.tfstate(client: client)).to eq({
            "aws_vpn_connection.vgw-1234abcd" => {
              "type" => "aws_vpn_connection",
              "primary" => {
                "id" => "vgw-1234abcd",
                "attributes" => {
                  "id"     => "vgw-1234abcd",
                  "tags.#" => "0",
                }
              }
            },
            "aws_vpn_connection.test" => {
              "type" => "aws_vpn_connection",
              "primary" => {
                "id" => "vgw-5678efgh",
                "attributes" => {
                  "id"     => "vgw-5678efgh",
                  "tags.#" => "1",
                }
              }
            },
          })
        end
      end
    end
  end
end
