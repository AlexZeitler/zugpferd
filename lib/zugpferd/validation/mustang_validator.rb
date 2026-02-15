require "open3"

module Zugpferd
  module Validation
    class MustangValidator
      Result = Struct.new(:valid, :output, keyword_init: true)

      CONTAINER_NAME = "zugpferd-mustang"
      IMAGE = "zugpferd-mustang:latest"

      # @param pdf_path [String] Pfad zur PDF-Datei
      # @return [Result]
      def validate(pdf_path)
        pdf_path = File.expand_path(pdf_path)
        dir = File.dirname(pdf_path)
        filename = File.basename(pdf_path)

        cmd = [
          "docker", "run", "--rm",
          "-v", "#{dir}:/data:ro",
          IMAGE,
          "--action", "validate",
          "--source", "/data/#{filename}",
        ]

        stdout, stderr, status = Open3.capture3(*cmd)
        output = "#{stdout}#{stderr}".strip

        Result.new(valid: status.success?, output: output)
      end

      # @return [Boolean] true wenn das Docker-Image vorhanden ist
      def available?
        _, _, status = Open3.capture3("docker", "image", "inspect", IMAGE)
        status.success?
      rescue Errno::ENOENT
        false
      end
    end
  end
end
