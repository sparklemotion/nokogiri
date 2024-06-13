# frozen_string_literal: true

require "helper"

class TestUnsafeXML < Nokogiri::TestCase
  describe "XML Signature URI" do
    it "does not allow file path URIs in signing references" do
      doc = Nokogiri::XML(File.open(File.join(ASSETS_DIR, "xmlsec/hate.xml")))
      exception = assert_raises(Nokogiri::XMLSec::SigningError) do
        doc.sign!(
          cert: File.read(File.join(ASSETS_DIR, "xmlsec/cert/server.crt")),
          key: File.read(File.join(ASSETS_DIR, "xmlsec/cert/server.key")),
          name: "test",
          signature_alg: "rsa-sha256",
          digest_alg: "sha256",
          uri: File.join(ASSETS_DIR, "xmlsec/pwned.xml"),
        )
      end
      assert_match(/error=44:invalid key data size/, exception.message)
    end

    it "does not allow file:// URIs in signing references" do
      doc = Nokogiri::XML(File.open(File.join(ASSETS_DIR, "xmlsec/hate.xml")))
      exception = assert_raises(Nokogiri::XMLSec::SigningError) do
        doc.sign!(
          cert: File.read(File.join(ASSETS_DIR, "xmlsec/cert/server.crt")),
          key: File.read(File.join(ASSETS_DIR, "xmlsec/cert/server.key")),
          name: "test",
          signature_alg: "rsa-sha256",
          digest_alg: "sha256",
          uri: "file://#{File.join(ASSETS_DIR, "xmlsec/pwned.xml")}",
        )
      end
      assert_match(/error=44:invalid key data size/, exception.message)
    end

    it "does not allow network URIs in signing references" do
      doc = Nokogiri::XML(File.open(File.join(ASSETS_DIR, "xmlsec/hate.xml")))
      exception = assert_raises(Nokogiri::XMLSec::SigningError) do
        doc.sign!(
          cert: File.read(File.join(ASSETS_DIR, "xmlsec/cert/server.crt")),
          key: File.read(File.join(ASSETS_DIR, "xmlsec/cert/server.key")),
          name: "test",
          signature_alg: "rsa-sha256",
          digest_alg: "sha256",
          uri: "http://www.w3.org/2001/XMLSchema.xsd",
        )
      end
      assert_match(/error=44:invalid key data size/, exception.message)
    end

    it "does allow empty signing references" do
      doc = Nokogiri::XML(File.open(File.join(ASSETS_DIR, "xmlsec/hate.xml")))
      doc.sign!(
        cert: File.read(File.join(ASSETS_DIR, "xmlsec/cert/server.crt")),
        key: File.read(File.join(ASSETS_DIR, "xmlsec/cert/server.key")),
        name: "test",
        signature_alg: "rsa-sha256",
        digest_alg: "sha256",
        uri: "",
      )
    end

    it "does allow same document signing references" do
      doc = Nokogiri::XML(File.open(File.join(ASSETS_DIR, "xmlsec/hate.xml")))
      doc.sign!(
        cert: File.read(File.join(ASSETS_DIR, "xmlsec/cert/server.crt")),
        key: File.read(File.join(ASSETS_DIR, "xmlsec/cert/server.key")),
        name: "test",
        signature_alg: "rsa-sha256",
        digest_alg: "sha256",
        uri: "#some_frackin_id",
      )
    end
  end
end
