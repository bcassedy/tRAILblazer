require 'erb'
require 'active_support/inflector'
require_relative 'params'
require_relative 'session'

class ControllerBase
  attr_reader :params, :req, :res

  # setup the controller
  def initialize(req, res, route_params = {})
    @req = req
    @res = res
    @params = Params.new(req, route_params).to_s
  end

  # populate the response with content
  # set the responses content type to the given type
  # later raise an error if the developer tries to double render
  def render_content(content, type)
    puts @params
    raise 'Only one render/redirect allowed' if already_built_response?
    @res.body = content
    @res.content_type = type
    @already_built_response = true
    session.store_session(@res)
  end

  # helper method to alias @already_built_response
  def already_built_response?
    @already_built_response
  end

  # set the response status code and header
  def redirect_to(url)
    raise 'Only one render/redirect allowed' if already_built_response?
    @res.status = 302
    @res.header['location'] = url
    @already_built_response = true
    session.store_session(@res)
  end

  # use ERB and binding to evaluate templates
  # pass the rendered html to render_content
  def render(template_name)
    controller = self.class.to_s.underscore
    f = "views/#{controller}/#{template_name}.html.erb"
    template = File.read(f)
    b = binding

    erb = ERB.new(template)
    render_content(erb.result(b), 'text/html')
  end

  # method exposing a `Session` object
  def session
    @session ||= Session.new(@req)
  end

  # use this with the router to call action_name (:index, :show, :create...)
  def invoke_action(name)
    self.send(name)
    render name unless already_built_response?
  end
end
