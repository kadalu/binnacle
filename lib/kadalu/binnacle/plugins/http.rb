# frozen_string_literal: true

require 'net/http'
require 'uri'

# rubocop:disable Metrics/ModuleLength
module Kadalu
  module Binnacle
    # Two ways to set the base URL
    # Using as Block
    #
    # ```
    # http_base_url "http://localhost:5001" do
    #   http_get "/api/users"
    # end
    # ```
    #
    # or without block
    #
    # ```
    # http_base_url "http://localhost:5001"
    # http_get "/api/users"
    # ```
    register_plugin 'http_base_url' do |value, &block|
      # TODO: Base URL validations
      Store.set(:base_url, URI.parse(value), &block)
    end

    default_config(:base_url, URI.parse(""))

    # Two ways to set the Basic auth
    # Using as Block
    #
    # ```
    # http_base_url "http://localhost:5001"
    # http_basic_auth "username", "password" do
    #   http_get "/api/users"
    # end
    # ```
    #
    # or without block
    #
    # ```
    # http_base_url "http://localhost:5001"
    # http_basic_auth "username", "password"
    # http_get "/api/users"
    # ```
    register_plugin 'http_basic_auth' do |username, password, &block|
      # TODO: Base URL validations
      Store.set(:basic_auth_username, username, &block)
      Store.set(:basic_auth_password, password, &block)
    end

    default_config(:basic_auth_username, nil)
    default_config(:basic_auth_password, nil)

    # Two ways to set the response type
    #
    # Using as Block
    #
    # ```
    # http_base_url "http://localhost:5001"
    # http_response_type "json" do
    #   resp = http_get "/api/users"
    #   puts resp[:json]
    # end
    # ```
    #
    # or without block
    #
    # ```
    # http_base_url "http://localhost:5001"
    # http_response_type "json"
    # resp = http_get "/api/users"
    # puts resp[:json]
    # ```
    register_plugin 'http_response_type' do |value, &block|
      Store.set(:response_type, value, &block)
    end

    default_config(:response_type, 'text')

    # Add a header to the request
    #
    # ```
    # http_base_url "http://localhost:5001"
    # http_add_header "Authorization", "Bearer 12345"
    # http_get "/api/folders"
    # ```
    register_plugin 'http_add_header' do |name, value, &block|
      Store.hash_add(:request_headers, name, value, &block)
    end

    # Remove header from the request
    #
    # ```
    # http_base_url "http://localhost:5001"
    # http_remove_header "Authorization"
    # http_get "/api/folders", status: 403
    # ```
    register_plugin 'http_remove_header' do |name, &block|
      Store.hash_remove(:request_headers, name, &block)
    end

    def self.get_http_from_url(url, kwargs)
      uri = Store.get(:base_url)

      # If full URL is given in sub commands then use the same instead of using Base URL
      uri = url.start_with?("http") ? URI.parse(url) : URI.join(uri.to_s, url)

      query = kwargs.fetch(:query, nil)

      uri.query = URI.encode_www_form(query) unless query.nil?

      http = Net::HTTP.new(uri.host, uri.port)

      if uri.scheme == 'https'
        # TODO: Add support for custom pem key
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end

      [uri, http]
    end

    def self.output_from_response(response)
      response_type = Store.get(:response_type)
      outdata = { status: response.code, body: response.body, json: nil }
      case response_type
      when 'json'
        begin
          outdata[:json] = JSON.parse(response.body)
        rescue JSON::ParserError
          outdata[:json] = nil
        end
      end

      outdata
    end

    def self.set_form_data(request, kwargs)
      form = kwargs.fetch(:form, nil)
      request.set_form_data(form) unless form.nil?
    end

    def self.set_multipart_data(request, kwargs)
      multipart = kwargs.fetch(:multipart, nil)
      return if multipart.nil?

      multipart_data = []
      multipart.each do |key, value|
        if value.is_a?(String) && value.start_with?('@')
          filepath = value.sub('@', '')
          filedata = File.open(filepath, 'rb')
          multipart_data << [key, filedata, { filename: File.basename(filepath) }]
        else
          multipart_data << [key, value.to_s]
        end
      end

      request.set_form(multipart_data, 'multipart/form-data') unless multipart_data.empty?
    end

    def self.set_request_body_or_json(request, kwargs)
      body = kwargs.fetch(:body, nil)
      request.body = body unless body.nil?

      # JSON data as String or Hash
      json_data = kwargs.fetch(:json, nil)
      return if json_data.nil?

      request['Content-Type'] = 'application/json'
      request.body = if json_data.is_a?(Hash)
                       json_data.to_json
                     else
                       json_data
                     end
    end

    def self.set_headers(request)
      headers = Store.get(:request_headers)
      return if headers.nil?

      headers.each do |key, value|
        request[key] = value.to_s
      end
    end

    def self.http_request(request_type, args, kwargs)
      uri, http = get_http_from_url(args[0], kwargs)

      request = case request_type
                when 'post' then Net::HTTP::Post.new(uri.request_uri)
                when 'put' then Net::HTTP::Put.new(uri.request_uri)
                when 'delete' then Net::HTTP::Delete.new(uri.request_uri)
                else Net::HTTP::Get.new(uri.request_uri)
                end

      # Set user set headers
      set_headers(request)

      # Form vars
      set_form_data(request, kwargs)

      # Multipart data
      set_multipart_data(request, kwargs)

      # Body String or JSON data
      set_request_body_or_json(request, kwargs)

      # Basic Auth
      ba_username = Store.get(:basic_auth_username)
      ba_password = Store.get(:basic_auth_password)

      request.basic_auth(ba_username, ba_password) unless ba_username.nil?

      status_code = kwargs.fetch(:status, 200).to_s

      begin
        response = http.request(request)
        ok = response.code == status_code
      rescue Errno::ECONNREFUSED
        return {
          ok: false,
          expected_status: status_code,
          actual_status: -1,
          error: 'Connection refused',
          output: { status: -1, body: nil, json: nil }
        }
      end

      {
        ok: ok,
        expected_status: status_code,
        actual_status: response.code,
        output: output_from_response(response)
      }
    end

    # Run HTTP Get for a given URL and compare the returned
    # status code
    #
    # ```
    # use_base_url "http://localhost:3001"
    # http_get "/api/users"
    # ```
    #
    # To validate the returned status code
    #
    # ```
    # use_base_url "http://localhost:3001"
    # http_get "/api/users", status: 200
    # ```
    register_plugin 'http_get' do |*args, **kwargs|
      http_request('get', args, kwargs)
    end

    # Run HTTP Post for a given URL and compare the returned
    # status code
    #
    # ```
    # use_base_url "http://localhost:3001"
    # data = {"name" => "Dummy", "email": "dummy@example.com"}
    # http_post "/api/users", form: data
    # ```
    #
    # To validate the returned status code
    #
    # ```
    # use_base_url "http://localhost:3001"
    # data = {"name" => "Dummy", "email": "dummy@example.com"}
    # http_post "/api/users", form: data, status: 201
    # ```
    register_plugin 'http_post' do |*args, **kwargs|
      http_request('post', args, kwargs)
    end

    # Run HTTP Post for a given URL and compare the returned
    # status code
    #
    # ```
    # use_base_url "http://localhost:3001"
    # data = {"email": "dummy1@example.com"}
    # http_put "/api/users/1", form: data
    # ```
    #
    # To validate the returned status code
    #
    # ```
    # use_base_url "http://localhost:3001"
    # data = {"email": "dummy1@example.com"}
    # http_put "/api/users/1", form: data, status: 200
    # ```
    register_plugin 'http_put' do |*args, **kwargs|
      http_request('put', args, kwargs)
    end

    # Run HTTP Delete for a given URL and compare the returned
    # status code
    #
    # ```
    # use_base_url "http://localhost:3001"
    # http_delete "/api/users/1"
    # ```
    #
    # To validate the returned status code
    #
    # ```
    # use_base_url "http://localhost:3001"
    # http_delete "/api/users/1", status: 204
    # ```
    register_plugin 'http_delete' do |*args, **kwargs|
      http_request('delete', args, kwargs)
    end
  end
end
# rubocop:enable Metrics/ModuleLength
