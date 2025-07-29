# -*- encoding: utf-8 -*-

# frozen_string_literal: true

require "helper"

module Nokogiri
  module XML
    module Security
      class TestSigning < Nokogiri::TestCase
        def setup
          super
          @xml = Nokogiri::XML(File.read(File.join(ASSETS_DIR, "xmlsec/sign2-doc.xml")))
          @private_key = File.read(File.join(ASSETS_DIR, "xmlsec/rsa.pem"))
          @public_key = File.read(File.join(ASSETS_DIR, "xmlsec/rsa.pub"))
          @certificate = File.read(File.join(ASSETS_DIR, "xmlsec/certificates/server.crt"))
          @certificate_private_key = File.read(File.join(ASSETS_DIR, "xmlsec/certificates/server.key.decrypted"))
        end

        def test_signing_with_rsa_key
          @xml.sign(@private_key,
            key_name: "test",
            signature_algorithm: "rsa-sha256",
            digest_algorithm: "sha256")

          assert_equal File.read(File.join(ASSETS_DIR, "xmlsec/sign2-result.xml")), @xml.to_s

          assert @xml.verify_signature(@public_key)
          keys_manager = KeysManager.new
          keys_manager.add_key("test", @public_key)
          assert @xml.verify_signature(keys_manager)
        end

        def test_signing_with_rsa_key_and_x509_certificate
          @xml.sign(@certificate_private_key,
            certificate: @certificate,
            signature_algorithm: "rsa-sha256",
            digest_algorithm: "sha256")

          assert_equal File.read(File.join(ASSETS_DIR, "xmlsec/sign3-result.xml")), @xml.to_s

          keys_manager = KeysManager.new
          keys_manager.add_certificate(@certificate)
          assert @xml.verify_signature(keys_manager)
        end

        %w[rsa-sha1 rsa-sha224 rsa-sha256 rsa-sha384 rsa-sha512].each do |signature_algorithm|
          define_method(:"test_signing_with_#{signature_algorithm.tr("-", "_")}") do
            assert @xml.sign(@certificate_private_key,
              certificate: @certificate,
              signature_algorithm: signature_algorithm,
              digest_algorithm: "sha256")

            assert @xml.sign(@certificate_private_key,
              key_name: "test",
              signature_algorithm: signature_algorithm,
              digest_algorithm: "sha256")
          end
        end

        # TODO: have ecdsa and dsa keys
        # %w[ecdsa-sha1
        #   ecdsa-sha224
        #   ecdsa-sha256
        #   ecdsa-sha384
        #   ecdsa-sha512
        #   dsa-sha1
        #   dsa-sha256].each do |signature_algorithm|
        #   define_method(:"test_signing_with_#{signature_algorithm.tr("-", "_")}") do
        #     key = something
        #     @xml.sign(key: key,
        #       key_name: "test",
        #       certificate: @certificate,
        #       signature_algorithm: signature_algorithm,
        #       digest_algorithm: "sha256")

        #     @xml.sign(key: key,
        #       key_name: "test",
        #       signature_algorithm: signature_algorithm,
        #       digest_algorithm: "sha256")
        #   end
        # end

        %w[sha1 sha224 sha256 sha384 sha512].each do |digest_algorithm|
          define_method(:"test_signing_with_digest_#{digest_algorithm}") do
            assert @xml.sign(@certificate_private_key,
              key_name: "test",
              certificate: @certificate,
              signature_algorithm: "rsa-sha256",
              digest_algorithm: digest_algorithm)

            assert @xml.sign(@certificate_private_key,
              key_name: "test",
              signature_algorithm: "rsa-sha256",
              digest_algorithm: digest_algorithm)
          end
        end
      end
    end
  end
end
