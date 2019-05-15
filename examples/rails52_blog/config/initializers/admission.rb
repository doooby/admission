require 'admission/rails'

Admission.debug_arbitration = -> (arbitration) {
  Rails.logger.info "Admission request: #{arbitration.case_to_s}"
}