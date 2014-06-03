require 'uri'
require 'active_support'

class Params
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
    key1 = key.to_s
    @params[key1]
  end

  def []=(key)
    key1 = key.to_s
    @params[key1]
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

  def parse_key(key)
    key.gsub(/[\[\]]/, ' ').split
  end
end
