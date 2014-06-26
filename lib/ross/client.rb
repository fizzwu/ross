# coding: utf-8
require 'rest-client'
require 'base64'

module ROSS
  class Client
    
    def initialize(options)
      return nil unless options
      @bucket_name = options[:bucket_name]
      @appid = options[:appid]
      @appkey = options[:appkey]
      @aliyun_host = options[:bucket_host] || "oss.aliyuncs.com"
      if options[:aliyun_internal] == true
        @aliyun_host = "oss-internal.aliyuncs.com"
      end
    end
    
    def put(path, content, options={})
      # content_md5 = Digest::MD5.hexdigest(content)
      content_type = options[:content_type] || "application/octet-stream"
      date = Time.now.gmtime.strftime("%a, %d %b %Y %H:%M:%S GMT")
      auth_sign = sign("PUT", path, date, content_type) #, content_md5)
      headers = {
        "Authorization" => "OSS #{@appid}:#{auth_sign}", 
        "Content-Type" => content_type,
        "Content-Length" => content.length,
        "Date" => date,
        "Host" => @aliyun_host,
      }
      response = RestClient.put(request_url(path), content, headers)
    end

    def put_file(path, file, options = {})
      put(path, File.read(file), options)
    end
    
    def public_url(path)
      "http://#{@bucket_name}.#{@aliyun_host}/#{path}"
    end

    alias :get :public_url

    def private_url(path, expires_in = 3600)
      expires_at = (8*3600 + Time.now.gmtime.to_i) + expires_in
      params = {
        'Expires' => expires_at,
        'OSSAccessKeyId' => @appid,
        'Signature' => sign('GET', path, expires_at)
      }
      public_url(path) + '?' + URI.encode_www_form(params)
    end
    
    private
    def sign(verb, path, date, content_type = nil, content_md5 = nil)
      canonicalized_oss_headers = ''
      canonicalized_resource = "/#{@bucket_name}/#{path.gsub(/^\//, '')}"
      string_to_sign = "#{verb}\n\n#{content_type}\n#{date}\n#{canonicalized_oss_headers}#{canonicalized_resource}"
      digest = OpenSSL::Digest.new('sha1')
      h = OpenSSL::HMAC.digest(digest, @appkey, string_to_sign)
      Base64.encode64(h).strip
    end

    def request_url(path)
      "http://#{@aliyun_host}/#{@bucket_name}/#{path}"
    end
  end
end