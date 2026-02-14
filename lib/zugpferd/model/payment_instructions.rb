module Zugpferd
  module Model
    class PaymentInstructions
      attr_accessor :payment_means_code, # BT-81
                    :payment_id,         # BT-83
                    :account_id,         # BT-84
                    :note                # BT-82 (PaymentTerms note)

      def initialize(payment_means_code:, **rest)
        @payment_means_code = payment_means_code
        rest.each { |k, v| public_send(:"#{k}=", v) }
      end
    end
  end
end
