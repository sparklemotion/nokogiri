# coding: utf-8
# frozen_string_literal: true

module Nokogiri
  module XML
    module Security
      class ErrorLocation
        attr_reader :func, :file, :line, :error_object, :error_subject, :reason, :error_message, :msg

        def to_s
          "func=#{func || "unknown"}:file=#{file || "unknown"}:line=#{line}:obj=#{error_object || "unknown"}:subj=#{error_subject || "unknown"}:error=#{reason}:#{error_message}:#{msg}"
        end
      end
    end
  end
end
