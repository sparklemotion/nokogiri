# frozen_string_literal: true

require "helper"

class TestEncryptionAndDecryption < Nokogiri::TestCase
  subject do
    Nokogiri::XML(File.open(File.join(ASSETS_DIR, "xmlsec/sign2-doc.xml")))
  end

  ["aes128-cbc", "aes192-cbc", "aes256-cbc", "tripledes-cbc"].each do |block_encryption|
    ["rsa-1_5", "rsa-oaep-mgf1p"].each do |key_transport|
      describe "encrypting with an RSA public key with #{block_encryption} #{key_transport}" do
        before do
          @original = subject.to_s
          subject.encrypt!(
            key: File.read(File.join(ASSETS_DIR, "xmlsec/rsa.pub")),
            name: "test",
            block_encryption: block_encryption,
            key_transport: key_transport,
          )
        end

        # it generates a new key every time so will never match the fixture
        specify { refute_equal(@original, subject.to_s) }
        specify { refute_match(/Hello.*World/i, subject.to_s) }
        # specify { subject.to_s.should == fixture('encrypt2-result.xml') }

        describe "decrypting with the RSA private key" do
          before do
            subject.decrypt!(key: File.read(File.join(ASSETS_DIR, "xmlsec/rsa.pem")))
          end

          specify { assert_equal(File.read(File.join(ASSETS_DIR, "xmlsec/sign2-doc.xml")), subject.to_s) }
        end
      end
    end
  end

  it "encrypts a single element" do
    doc = subject
    original = doc.to_s
    node = doc.at_xpath("env:Envelope/env:Data", "env" => "urn:envelope")
    node.encrypt_with(key: File.read(File.join(ASSETS_DIR, "xmlsec/rsa.pub")), block_encryption: "aes128-cbc", key_transport: "rsa-1_5")
    assert_equal("Envelope", doc.root.name)
    assert_equal("EncryptedData", doc.root.element_children.first.name)
    encrypted_data = doc.root.element_children.first
    encrypted_data.decrypt_with(key: File.read(File.join(ASSETS_DIR, "xmlsec/rsa.pem")))
    assert_equal(original, doc.to_s)
  end

  it "inserts a certificate" do
    doc = subject
    doc.encrypt!(
      key: File.read(File.join(ASSETS_DIR, "xmlsec/cert/server.key")),
      cert: File.read(File.join(ASSETS_DIR, "xmlsec/cert/server.crt")),
      block_encryption: "aes128-cbc",
      key_transport: "rsa-1_5",
    )
    assert_match(/X509Data/, doc.to_s)
    refute_match(/X509Data></, doc.to_s)
  end
end
