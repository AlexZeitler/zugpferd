require "net/http"
require "uri"
require "json"

module Zugpferd
  module Validation
    class PdfValidator
      Result = Struct.new(:compliant, :failures, keyword_init: true)

      def initialize(host: "localhost", port: 8080)
        @base_uri = URI("http://#{host}:#{port}")
      end

      # @param pdf_path [String] Pfad zur PDF-Datei
      # @param profile [String] veraPDF-Profil ("3b", "3a", "3u")
      # @return [Result]
      def validate(pdf_path, profile: "3b")
        uri = URI("#{@base_uri}/api/validate/#{profile}")

        boundary = "----ZugpferdBoundary#{SecureRandom.hex(16)}"
        body = build_multipart_body(pdf_path, boundary)

        request = Net::HTTP::Post.new(uri)
        request["Content-Type"] = "multipart/form-data; boundary=#{boundary}"
        request["Accept"] = "application/json"
        request.body = body

        response = Net::HTTP.start(uri.hostname, uri.port) do |http|
          http.read_timeout = 120
          http.request(request)
        end

        parse_response(response)
      end

      # @return [Boolean] true wenn veraPDF erreichbar ist
      def available?
        uri = URI("#{@base_uri}/api/info")
        response = Net::HTTP.get_response(uri)
        response.code == "200"
      rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH, SocketError, Net::OpenTimeout
        false
      end

      private

      def build_multipart_body(pdf_path, boundary)
        filename = File.basename(pdf_path)
        content = File.binread(pdf_path)

        body = +""
        body << "--#{boundary}\r\n"
        body << "Content-Disposition: form-data; name=\"file\"; filename=\"#{filename}\"\r\n"
        body << "Content-Type: application/pdf\r\n"
        body << "\r\n"
        body << content
        body << "\r\n"
        body << "--#{boundary}--\r\n"
        body
      end

      def parse_response(response)
        unless response.code == "200"
          raise "veraPDF returned HTTP #{response.code}: #{response.body}"
        end

        data = JSON.parse(response.body)
        job = data.dig("report", "jobs", 0) || data.dig("report", "batchSummary") || {}
        validation = job["validationResult"] || job

        compliant = validation["compliant"] == true
        failures = extract_failures(validation)

        Result.new(compliant: compliant, failures: failures)
      end

      def extract_failures(validation)
        details = validation["details"] || validation["rulesSummary"] || {}
        rules = details["rules"] || []

        rules.select { |r| r["status"] == "failed" }.map do |rule|
          {
            clause: rule["clause"],
            test_number: rule["testNumber"],
            description: rule["description"],
            object: rule["object"],
            checks: rule["checks"]&.select { |c| c["status"] == "failed" },
          }
        end
      end
    end
  end
end
