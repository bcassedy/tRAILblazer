require 'erb'
require 'active_support/inflector'
require 'securerandom'
require_relative 'params'
require_relative 'session'
require_relative 'flash'
require_relative 'csrf_helper'

class ControllerBase
  include CSRFHelper
  extend CSRFHelper
  attr_reader :params, :req, :res, :flash

  def initialize(req, res, route_params = {})
    @req = req
    @res = res
    @params = Params.new(req, route_params)
    @flash = Flash.new(req)
    session
  end

  def render_content(content, type)
    raise 'Only one render/redirect allowed' if already_built_response?
    if protect_from_forgery? && !verified_request?
      raise 'Could Not Authenticate CSRF Token'
    end
    @res.body = content
    @res.content_type = type
    @already_built_response = true
    session.store_session(@res)
  end

  def already_built_response?
    @already_built_response
  end

  def redirect_to(url)
    raise 'Only one render/redirect allowed' if already_built_response?
    if protect_from_forgery? && !verified_request?
      raise 'Could Not Authenticate CSRF Token'
    end
    @res.status = 302
    @res.header['location'] = url
    @already_built_response = true
    session.store_session(@res)
  end

  def render(template_name)
    if protect_from_forgery? && !verified_request?
      raise 'Could Not Authenticate CSRF Token'
    end
    controller = self.class.to_s.underscore
    f = "views/#{controller}/#{template_name}.html.erb"
    template = File.read(f)
    b = binding

    erb = ERB.new(template)
    render_content(erb.result(b), 'text/html')
  end

  def session
    @session ||= Session.new(@req)
  end

  def invoke_action(name)
    send(name)
    render name unless already_built_response?
  end
end
