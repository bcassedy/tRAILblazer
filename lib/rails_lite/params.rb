require 'uri'
require 'active_support'

class Params
  # use your initialize to merge params from
  # 1. query string
  # 2. post body
  # 3. route params
  def initialize(req, route_params = {})
    @req = req
    @params = route_params
    if @req.query_string
      parse_www_encoded_form(@req.query_string)
    elsif @req.body
      parse_www_encoded_form(@req.body)
    end
    @permitted_keys = []
  end

  def [](key)
    @params[key]
  end

  def permit(*keys)
    @permitted_keys += keys
  end

  def require(key)
    raise AttributeNotFoundError unless @params.include?(key)
  end

  def permitted?(key)
    @permitted_keys.include?(key)
  end

  def to_s
    @params
  end

  class AttributeNotFoundError < ArgumentError; end;

  private
  # this should return deeply nested hash
  # argument format
  # user[address][street]=main&user[address][zip]=89436
  # should return
  # { "user" => { "address" => { "street" => "main", "zip" => "89436" } } }
  def parse_www_encoded_form(www_encoded_form)
    hashes = []
    URI.decode_www_form(www_encoded_form).each do |key_val_pair|
      hash_keys = parse_key(key_val_pair.first)
      last_hash = { hash_keys.last => key_val_pair.last }
      hashes << nest_hashes(hash_keys[0..-1], last_hash)
    end
    hashes.each do |hash|
      @params = @params.deep_merge(hash)
    end
  end

  def nest_hashes(hash_keys, last_hash)
    return last_hash if hash_keys.count == 1
    { hash_keys[0] => nest_hashes(hash_keys[1..-1], last_hash) }
  end


  # this should return an array
  # user[address][street] should return ['user', 'address', 'street']
  def parse_key(key)
    key.gsub(/[\[\]]/, ' ').split
  end

  parse_www_encoded_form('cat[toy][fname]=mouse&cat[name]=earl')
end
