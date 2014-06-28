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
    
    def put(path, content, options={}, xoss = {})
      # content_md5 = Digest::MD5.hexdigest(content)
      content_type = options.has_key?(:content_type) ? options[:content_type] : "application/octet-stream"
      date = Time.now.gmtime.strftime("%a, %d %b %Y %H:%M:%S GMT")
      headers = {
        "Authorization" => auth_sign("PUT", path, date, content_type, nil, xoss),
        "Content-Type" => content_type,
        "Date" => date,
        "Host" => @aliyun_host
      }
      headers["Content-Length"] = content.length unless content.nil? # content can be nil
      xoss.each_pair{|k,v| headers["x-oss-#{k}"] = v }
      response = RestClient.put(request_url(path), content, headers)
    end

    def delete(path)
      date = Time.now.gmtime.strftime("%a, %d %b %Y %H:%M:%S GMT")
      content_type = nil
      headers = {
        "Authorization" => auth_sign("DELETE", path, date, content_type),
        "Content-Type" => content_type,
        "Date" => date,
        "Host" => @aliyun_host
      }
      RestClient.delete(request_url(path), headers)
    end

    def copy(sour_path, dest_path)
      put(dest_path, nil, {content_type: nil}, {'copy-source' => bucket_path(sour_path)})
    end

    def rename(sour_path, dest_path)
      copy(sour_path, dest_path)
      delete(path)
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
    def sign(verb, path, date, content_type = nil, content_md5 = nil, xoss = {})
      canonicalized_oss_headers = xoss.sort.map{|k,v| "x-oss-#{k}:".downcase + v + "\n"}.join
      canonicalized_resource = bucket_path(path)
      string_to_sign = "#{verb}\n\n#{content_type}\n#{date}\n#{canonicalized_oss_headers}#{canonicalized_resource}"
      digest = OpenSSL::Digest.new('sha1')
      h = OpenSSL::HMAC.digest(digest, @appkey, string_to_sign)
      Base64.encode64(h).strip
    end

    def auth_sign(verb, path, date, content_type = nil, content_md5 = nil, xoss = {})
      "OSS #{@appid}:#{sign(verb, path, date, content_type, content_md5, xoss)}"
    end

    def bucket_path(path)
      "/#{@bucket_name}/#{path.gsub(/^\//, '')}"
    end

    def request_url(path)
      "http://#{@aliyun_host}/#{@bucket_name}/#{URI.encode(path)}"
    end
  end
end