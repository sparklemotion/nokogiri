# coding: utf-8
# frozen_string_literal: true

require "helper"

class TestSerializationEncoding < Nokogiri::TestCase
  def round_trip_through_file
    Tempfile.create do |io|
      yield io
      io.rewind
      io.read
    end
  end

  describe "serialization encoding" do
    matrix = [
      {
        klass: Nokogiri::XML::Document,
        documents: [
          { encoding: Encoding::UTF_8, path: ADDRESS_XML_FILE },
          { encoding: Encoding::Shift_JIS, path: SHIFT_JIS_XML },
        ],
      },
      {
        klass: Nokogiri::HTML4::Document,
        documents: [
          { encoding: Encoding::UTF_8, path: HTML_FILE },
          { encoding: Encoding::Shift_JIS, path: SHIFT_JIS_HTML },
        ],
      },
    ]
    if Nokogiri.uses_gumbo?
      matrix << {
        klass: Nokogiri::HTML5::Document,
        documents: [
          { encoding: Encoding::UTF_8, path: HTML_FILE },
          { encoding: Encoding::Shift_JIS, path: SHIFT_JIS_HTML },
        ],
      }
    end

    matrix.each do |matrix_entry|
      describe matrix_entry[:klass] do
        let(:klass) { matrix_entry[:klass] }
        matrix_entry[:documents].each do |document|
          describe document[:encoding] do
            it "serializes with the expected encoding" do
              doc = klass.parse(
                File.read(
                  document[:path],
                  encoding: document[:encoding],
                ),
              )

              expected_default_encoding =
                if defined?(Nokogiri::HTML5::Document) && klass == Nokogiri::HTML5::Document
                  Encoding::UTF_8 # FIXME: see #2801, this should be document[:encoding]
                else
                  document[:encoding]
                end

              assert_equal(expected_default_encoding, doc.to_s.encoding)

              assert_equal(expected_default_encoding, doc.to_xml.encoding)
              assert_equal(Encoding::UTF_8, doc.to_xml(encoding: "UTF-8").encoding)
              assert_equal(Encoding::Shift_JIS, doc.to_xml(encoding: "SHIFT_JIS").encoding)
              assert_equal(Encoding::UTF_8, doc.to_xml(encoding: Encoding::UTF_8).encoding)
              assert_equal(Encoding::Shift_JIS, doc.to_xml(encoding: Encoding::Shift_JIS).encoding)

              assert_equal(expected_default_encoding, doc.to_xhtml.encoding)
              assert_equal(Encoding::UTF_8, doc.to_xhtml(encoding: "UTF-8").encoding)
              assert_equal(Encoding::Shift_JIS, doc.to_xhtml(encoding: "SHIFT_JIS").encoding)
              assert_equal(Encoding::UTF_8, doc.to_xhtml(encoding: Encoding::UTF_8).encoding)
              assert_equal(Encoding::Shift_JIS, doc.to_xhtml(encoding: Encoding::Shift_JIS).encoding)

              assert_equal(expected_default_encoding, doc.to_html.encoding)
              assert_equal(Encoding::UTF_8, doc.to_html(encoding: "UTF-8").encoding)
              assert_equal(Encoding::Shift_JIS, doc.to_html(encoding: "SHIFT_JIS").encoding)
              assert_equal(Encoding::UTF_8, doc.to_html(encoding: Encoding::UTF_8).encoding)
              assert_equal(Encoding::Shift_JIS, doc.to_html(encoding: Encoding::Shift_JIS).encoding)

              assert_equal(expected_default_encoding, doc.serialize.encoding)
              assert_equal(Encoding::UTF_8, doc.serialize(encoding: "UTF-8").encoding)
              assert_equal(Encoding::Shift_JIS, doc.serialize(encoding: "SHIFT_JIS").encoding)
              assert_equal(Encoding::UTF_8, doc.serialize(encoding: Encoding::UTF_8).encoding)
              assert_equal(Encoding::Shift_JIS, doc.serialize(encoding: Encoding::Shift_JIS).encoding)

              assert_equal(
                doc.serialize.bytes,
                round_trip_through_file { |io| doc.write_to(io) }.bytes,
              )
              assert_equal(
                doc.serialize(encoding: "UTF-8").bytes,
                round_trip_through_file { |io| doc.write_to(io, encoding: "UTF-8") }.bytes,
              )
              assert_equal(
                doc.serialize(encoding: "SHIFT_JIS").bytes,
                round_trip_through_file { |io| doc.write_to(io, encoding: "SHIFT_JIS") }.bytes,
              )
              assert_equal(
                doc.serialize(encoding: "UTF-8").bytes,
                round_trip_through_file { |io| doc.write_to(io, encoding: Encoding::UTF_8) }.bytes,
              )
              assert_equal(
                doc.serialize(encoding: "Shift_JIS").bytes,
                round_trip_through_file { |io| doc.write_to(io, encoding: Encoding::Shift_JIS) }.bytes,
              )
            end
          end
        end
      end
    end
  end
end
