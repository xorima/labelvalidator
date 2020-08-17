# frozen_string_literal: true

def verify_signature(payload_body)
  signature = 'sha1=' + OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha1'), ENV['SECRET_TOKEN'], payload_body)
  Rack::Utils.secure_compare(signature, request.env['HTTP_X_HUB_SIGNATURE'])
end
