# -*- encoding: utf-8 -*-
# frozen_string_literal: true

require "helper"

module Nokogiri
  module XML
    module Security
      class TestEncryption < Nokogiri::TestCase
        def setup
          super

          @xml = Nokogiri::XML(File.read(File.join(ASSETS_DIR, "xmlsec/sign2-doc.xml")))
          @public_key = File.read(File.join(ASSETS_DIR, "xmlsec/rsa.pub"))
          @private_key = File.read(File.join(ASSETS_DIR, "xmlsec/rsa.pem"))
        end

        %w[aes128-cbc aes192-cbc aes256-cbc tripledes-cbc].each do |block_encryption|
          %w[rsa-1_5 rsa-oaep-mgf1p].each do |key_transport|
            define_method(:"test_encrypt_#{block_encryption.tr("-", "_")}_#{key_transport.tr("-", "_")}") do
              original = @xml.to_s

              @xml.encrypt(
                @public_key,
                key_name: "test",
                block_encryption:,
                key_transport:,
              )

              # it generates a new key every time so will never match the fixture
              # assert_equal File.read(ASSETS_DIR.join("xmlsec/encrypt2-result.xml")), @xml.to_s
              refute_equal original, @xml.to_s
              refute_match(/Hello.*World/i, @xml.to_s)

              @xml.decrypt(@private_key)
              assert_equal original, @xml.to_s
            end
          end
        end

        def test_encrypt_single_element
          skip_unless_libxml2("java version doesn't support this feature")

          doc = @xml
          original = doc.to_s
          node = doc.at_xpath("env:Envelope/env:Data", "env" => "urn:envelope")
          node.encrypt(@public_key,
            key_name: "test",
            block_encryption: "aes128-cbc",
            key_transport: "rsa-1_5")
          assert_equal "Envelope", doc.root.name
          assert_equal "EncryptedData", doc.root.element_children.first.name
          encrypted_data = doc.root.element_children.first
          encrypted_data.decrypt(@private_key)
          assert_equal original, doc.to_s
        end

        def test_certificate_insertion
          skip_unless_libxml2("java version doesn't support this feature")

          doc = @xml
          doc.encrypt(File.read(File.join(ASSETS_DIR, "xmlsec/certificates/server.key.decrypted")),
            certificate: File.read(File.join(ASSETS_DIR, "xmlsec/certificates/server.crt")),
            block_encryption: "aes128-cbc",
            key_transport: "rsa-1_5")
          assert_match(/X509Data/, doc.to_s)
          refute_match(/X509Data></, doc.to_s)
        end
      end
    end
  end
end
