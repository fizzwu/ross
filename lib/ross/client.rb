# coding: utf-8
require 'rest-client'

module ROSS
  class Client
    
    def initialize(options)
      return nil unless options
      @bucket_name = options[:bucket_name]
      @appid = options[:appid]
      @appkey = options[:appkey]
      @aliyun_host = "oss.aliyuncs.com"
      if options[:aliyun_internal] == true
        @aliyun_host = "oss-internal.aliyuncs.com"
      end
    end
    
    def put(path, file, options={})
      content_md5 = Digest::MD5.hexdigest(file)
      content_type = options[:content_type] || "image/jpg"
      date = Time.now.gmtime.strftime("%a, %d %b %Y %H:%M:%S GMT")
      path = "#{@bucket_name}/#{path}"
      url = "http://#{@aliyun_host}/#{path}"
      auth_sign = sign("PUT", path, content_md5, content_type, date)
      headers = {
                  "Authorization" => auth_sign, 
                  "Content-Type" => content_type,
                  "Content-Length" => file.length,
                  "Date" => date,
                  "Host" => @aliyun_host,
                }
                
      response = RestClient.put(url, file, headers)
    end
    
    def get(path)
      return "http://#{@bucket_name}.#{@aliyun_host}/#{path}"
    end
    
    private
    def sign(verb, path, content_md5, content_type, date)
      canonicalized_oss_headers = ''
      canonicalized_resource = "/#{path}"
      string_to_sign = "#{verb}\n\n#{content_type}\n#{date}\n#{canonicalized_oss_headers}#{canonicalized_resource}"
      digest = OpenSSL::Digest::Digest.new('sha1')
      h = OpenSSL::HMAC.digest(digest, @appkey, string_to_sign)
      h = Base64.encode64(h)
      "OSS #{@appid}:#{h}"
    end
  end
end