require 'json'
require 'webrick'
require_relative 'csrf_helper'

class Session
  include CSRFHelper
  def initialize(req)
    req.cookies.each do |cookie|
      @cookie = JSON.parse(cookie.value) if cookie.name == '_rails_lite_app'
    end
    @cookie ||= {}
  end

  def [](key)
    @cookie[key]
  end

  def []=(key, val)
    @cookie[key] = val
  end

  def store_session(res)
    @cookie['_csrf_token'] ||= create_auth_token
    res.cookies << WEBrick::Cookie.new('_rails_lite_app', @cookie.to_json)
  end
end
