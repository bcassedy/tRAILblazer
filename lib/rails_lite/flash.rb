require 'json'
require 'webrick'

class Flash
  def initialize(req)
    req.cookies.each do |cookie|
      @flash = JSON.parse(cookie.value) if cookie.name == 'flash'
    end
    @flash ||= {}
  end

  def [](key)
    @flash[key]
  end

  def []=(key, val)
    @flash[key] = val
  end

  def store_session(res)
    res.cookies << WEBrick::Cookie.new('flash', @flash.to_json)
  end
end
