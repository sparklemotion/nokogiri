# frozen_string_literal: true

require "helper"

class TestSiginingAndVerifying < Nokogiri::TestCase
  subject do
    Nokogiri::XML(File.open(File.join(ASSETS_DIR, "xmlsec/sign2-doc.xml")))
  end

  describe "signing a document with an RSA key" do
    before do
      subject.sign!(
        key: File.read(File.join(ASSETS_DIR, "xmlsec/rsa.pem")),
        name: "test",
        signature_alg: "rsa-sha256",
        digest_alg: "sha256",
      )
    end

    it "should produce a signed document" do
      assert_equal(File.read(File.join(ASSETS_DIR, "xmlsec/sign2-result.xml")), subject.to_s)
    end

    describe "verifying the document with a single public key" do
      it "should be valid" do
        assert(subject.verify_with(key: File.read(File.join(ASSETS_DIR, "xmlsec/rsa.pub"))))
      end
    end

    describe "verifying the document with a set of keys" do
      it "should be valid" do
        assert(subject.verify_with({
          "test" => File.read(File.join(ASSETS_DIR, "xmlsec/rsa.pub")),
        }))
      end
    end
  end

  describe "signing a document with an RSA key and X509 certificate" do
    before do
      subject.sign!(
        key: File.read(File.join(ASSETS_DIR, "xmlsec/cert/server.key")),
        cert: File.read(File.join(ASSETS_DIR, "xmlsec/cert/server.crt")),
        signature_alg: "rsa-sha256",
        digest_alg: "sha256",
      )
    end

    it "should produce a signed document" do
      assert_equal(File.read(File.join(ASSETS_DIR, "xmlsec/sign3-result.xml")), subject.to_s)
    end

    describe "verifying the document with an array of X509 certificates" do
      specify do
        assert(subject.verify_with(cert: [File.read(File.join(ASSETS_DIR, "xmlsec/cert/server.crt"))]))
      end

      it "should verify using system certificates" do
        pending("Testing system certs requires admin privs. Read exception message in code.") do
          assert(subject.verify_signature)
        rescue Nokogiri::XMLSec::VerificationError => e
          # Could not use system certificates to verify the signature.
          # Note that this may not be a failing spec. You should copy
          # or symlink the file `spec/fixtures/cert/server.crt` into
          # the directory shown by running `openssl version -d`. After
          # doing so, run `sudo c_rehash CERT_PATH`, where
          # CERT_PATH is the same directory you copied the certificate
          # into (/usr/lib/ssl/certs by default on Ubuntu). After doing
          # that, run this spec again and see if it passes.
          flunk("System cert verification failed #{e}")
        end
      end
    end

    describe "verifying the document with one X509 certificate" do
      specify do
        assert(subject.verify_with(cert: File.read(File.join(ASSETS_DIR, "xmlsec/cert/server.crt"))))
      end
    end
  end
  describe "test all signature algorithms" do
    ["rsa-sha1", "rsa-sha224", "rsa-sha256", "rsa-sha384", "rsa-sha512"].each do |signature_algorithm|
      specify "#{signature_algorithm} signatures work with cert signing" do
        subject.sign!(
          key: File.read(File.join(ASSETS_DIR, "xmlsec/cert/server.key")),
          cert: File.read(File.join(ASSETS_DIR, "xmlsec/cert/server.crt")),
          signature_alg: signature_algorithm,
          digest_alg: "sha256",
        )
      end
      specify "#{signature_algorithm} signatures work with bare key signing" do
        subject.sign!(
          key: File.read(File.join(ASSETS_DIR, "xmlsec/cert/server.key")),
          name: "test",
          signature_alg: signature_algorithm,
          digest_alg: "sha256",
        )
      end
    end
    ["ecdsa-sha1", "ecdsa-sha224", "ecdsa-sha256", "ecdsa-sha384", "ecdsa-sha512", "dsa-sha1", "dsa-sha256"].each do |signature_algorithm|
      cert_type = signature_algorithm.split("-").first
      specify "#{signature_algorithm} signatures work with cert signing" do
        skip("Removed from modern openssl") if signature_algorithm == "dsa-sha1"

        subject.sign!(
          key: File.read(File.join(ASSETS_DIR, "xmlsec/cert/server-#{cert_type}.key")),
          name: "test",
          cert: File.read(File.join(ASSETS_DIR, "xmlsec/cert/server-#{cert_type}.crt")),
          signature_alg: signature_algorithm,
          digest_alg: "sha256",
        )
      end
      specify "#{signature_algorithm} signatures work with bare key" do
        skip("Removed from modern openssl") if signature_algorithm == "dsa-sha1"

        subject.sign!(
          key: File.read(File.join(ASSETS_DIR, "xmlsec/cert/server-#{cert_type}.key")),
          name: "test",
          signature_alg: signature_algorithm,
          digest_alg: "sha256",
        )
      end
    end
  end
  describe "test all digest algorithms" do
    ["sha1", "sha224", "sha256", "sha384", "sha512"].each do |digest_algorithm|
      specify "#{digest_algorithm} digests with cert" do
        subject.sign!(
          key: File.read(File.join(ASSETS_DIR, "xmlsec/cert/server.key")),
          name: "test",
          cert: File.read(File.join(ASSETS_DIR, "xmlsec/cert/server.crt")),
          signature_alg: "rsa-sha256",
          digest_alg: digest_algorithm,
        )
      end
      specify "#{digest_algorithm} digests with bare key" do
        subject.sign!(
          key: File.read(File.join(ASSETS_DIR, "xmlsec/cert/server.key")),
          name: "test",
          signature_alg: "rsa-sha256",
          digest_alg: digest_algorithm,
        )
      end
    end
  end
end
