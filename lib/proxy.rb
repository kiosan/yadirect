module Yadirect
  class Proxy
    EP_YANDEX_DIRECT_V4 = 'https://soap.direct.yandex.ru/json-api/v4/'
    attr_accessor :debug, :locale

    def initialize params
      @params = params
      @locale = 'RU' || params[:locale]
      @debug = false || params[:debug]
      @login = params[:login]
      @app_id = params[:application_id]
      @token = params[:token]
    end

    def invoke method, args

      args = case args
        when Hash then args.camelize_keys
        when Array then args.camelize_each
        else args
      end
      json_object = JSON.generate({:method => method, :login => @login, :application_id => @app_id, :token=>@token, :locale => @locale, :param => args})
      puts "yadirect input: #{json_object}" if @debug
      c = Curl::Easy.http_post(EP_YANDEX_DIRECT_V4, json_object) do |curl|
        #curl.cacert = @params[:cacert]
        #curl.certtype = "PEM"
        #curl.cert_key = @params[:cert_key]
        #curl.cert = @params[:cert]
        curl.encoding = Encoding::UTF_8.name
        curl.headers['Accept'] = 'application/json'
        curl.headers['Content-Type'] = 'application/json'
        curl.headers['Api-Version'] = '2.2'
      end

      hash =  JSON.parse(c.body_str)
      puts "yadirect output: #{hash}" if @debug

      if (hash.include?("error_code"))
        raise Yadirect::ApiError, hash
      else
        hash["data"]
      end
    end

    def method_missing(name, *args, &block)
      ya_params = to_hash_params(*args)
      object = invoke(name.to_s.to_camelcase, ya_params)
    end

    def to_hash_params *args
      return {} if args.empty?
      params = args.first[:params]
      return params.is_a?(Hash) ? params.camelize_keys : params.flatten
    end

  end
end
