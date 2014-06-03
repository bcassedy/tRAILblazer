class Route
  attr_reader :pattern, :http_method, :controller_class, :action_name

  def initialize(pattern, http_method, controller_class, action_name)
    @pattern = pattern
    @http_method = http_method
    @controller_class = controller_class
    @action_name = action_name
  end

  def matches?(req)
    req.request_method.downcase.to_sym == @http_method &&
      req.path =~ @pattern
  end

  def run(req, res)
    capture_names = @pattern.named_captures
    captures = @pattern.match(req.path).captures
    route_params = {}
    capture_names.keys.each_with_index do |name, i|
      route_params[name] = captures[i]
    end
    controller = @controller_class.new(req, res, route_params)
    controller.invoke_action(@action_name)
  end
end

class Router
  attr_reader :routes

  def initialize
    @routes = []
  end

  def add_route(pattern, method, controller_class, action_name)
    @routes << Route.new(pattern, method, controller_class, action_name)
  end

  def draw(&proc)
    instance_eval(&proc)
  end

  [:get, :post, :put, :delete].each do |http_method|
    define_method(http_method) do  |pattern, controller_class, action_name|
      add_route(pattern, http_method, controller_class, action_name)
    end
  end

  def match(req)
    m = @routes.select { |route| route.matches?(req) }
    m.empty? ? nil : m.first
  end

  def run(req, res)
    m = match(req)
    m.nil? ? res.status = 404 : m.run(req, res)
  end
end
