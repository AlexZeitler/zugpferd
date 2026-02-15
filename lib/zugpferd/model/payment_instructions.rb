module Zugpferd
  module Model
    # Payment instructions (BG-16) including payment card (BG-18)
    # and direct debit (BG-19) information.
    class PaymentInstructions
      # @return [String] BT-81 Payment means type code
      # @return [String, nil] BT-83 Remittance information
      # @return [String, nil] BT-84 Payment account identifier (IBAN)
      # @return [String, nil] BT-82 Payment terms note
      # @return [String, nil] BT-87 Payment card primary account number
      # @return [String, nil] BT-88 Payment card holder name
      # @return [String, nil] Card network ID (UBL-only, required in CardAccount)
      # @return [String, nil] BT-89 Mandate reference identifier
      # @return [String, nil] BT-90 Bank assigned creditor identifier
      # @return [String, nil] BT-91 Debited account identifier
      attr_accessor :payment_means_code, :payment_id, :account_id, :note,
                    :card_account_id, :card_holder_name, :card_network_id,
                    :mandate_reference, :creditor_reference_id,
                    :debited_account_id

      # @param payment_means_code [String] BT-81 Payment means type code
      # @param rest [Hash] additional attributes set via accessors
      def initialize(payment_means_code:, **rest)
        @payment_means_code = payment_means_code
        rest.each { |k, v| public_send(:"#{k}=", v) }
      end
    end
  end
end
