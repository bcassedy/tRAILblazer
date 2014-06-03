require 'securerandom'

module CSRFHelper

  def protect_from_forgery?
    unless @req.request_method == 'GET' || @req.request_method == 'HEAD'
      true
    else
      false
    end
  end

  def verified_request?
    session['_csrf_token'] == params['authenticity_token']
  end


  def create_auth_token
    SecureRandom.hex
  end
end