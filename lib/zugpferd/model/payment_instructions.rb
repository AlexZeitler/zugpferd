module Zugpferd
  module Model
    class PaymentInstructions
      attr_accessor :payment_means_code,   # BT-81
                    :payment_id,           # BT-83
                    :account_id,           # BT-84
                    :note,                 # BT-82 (PaymentTerms note)
                    :card_account_id,      # BT-87
                    :card_holder_name,     # BT-88
                    :card_network_id,      # UBL-only (required in CardAccount)
                    :mandate_reference,    # BT-89
                    :creditor_reference_id, # BT-90
                    :debited_account_id    # BT-91

      def initialize(payment_means_code:, **rest)
        @payment_means_code = payment_means_code
        rest.each { |k, v| public_send(:"#{k}=", v) }
      end
    end
  end
end
