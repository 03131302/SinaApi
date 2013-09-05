# encoding: UTF-8
require 'rubygems'
require 'oauth'
require 'iconv'

module Oauth_QQ

  class OAuth
    attr_accessor :request_token, :access_token, :consumer_options

    def initialize(request_token = nil, request_token_secret = nil)
      if request_token && request_token_secret
        @request_token = ::OAuth::RequestToken.new(consumer, request_token, request_token_secret)
      else
        consumer
        @request_token = consumer.get_request_token(:oauth_callback => self.callback)
      end
      # 2. 授权
      puts ("拷贝URL到浏览器进行授权:")
      puts authorize_url
      #程序中断等待授权完成
      puts ("请等待授权完成之后输入ok！")
      a = gets
      puts ("授权已经完成#{a}")
      aaa = gets
      puts aaa
      @access_token = authorize(:oauth_verifier => aaa[0, 6])
      puts @access_token
    end

    #每次认证的唯一标志
    def oauth_token
      @request_token.params[:oauth_token]
    end

    def consumer
      @consumer ||= ::OAuth::Consumer.new(key, secret, consumer_options)
    end

    def key;
      "bbbe0c34006e46db96d0c0a6355099f2"
    end

    def secret;
      "f59b4ca82f88ecf983bdf61fbf3c6f18"
    end

    def url;
      "http://10.207.1.147:8090/eip/login.eip"
    end

    def callback;
      "http://10.207.1.147:8090/eip/login.eip"
    end

    def authorize_url
      @authorize_url ||= @request_token.authorize_url(:oauth_callback => URI.encode(callback))
    end

    def authorize(options = {})
      token = @request_token.get_access_token(options)
      @access_token ||= ::OAuth::AccessToken.new(consumer, token.token, token.secret)
    end

  end


  class QQ_AAuth < Oauth_QQ::OAuth

    def initialize(*args)
      self.consumer_options = {
          :site => "https://open.t.qq.com",
          :request_token_path => "/cgi-bin/request_token",
          :access_token_path => "/cgi-bin/access_token",
          :authorize_path => "/cgi-bin/authorize",
          :http_method => :get,
          :scheme => :query_string,
          :nonce => nonce,
          :realm => url
      }
      super(*args)
    end

    def name
      :qq
    end

    #腾讯的nonce值必须32位随机字符串啊！
    def nonce
      Base64.encode64(OpenSSL::Random.random_bytes(32)).gsub(/\W/, '')[0, 32]
    end

    def authorized?
    end

    def destroy
    end

    def to_gbk(ostring)
      Iconv.iconv("GBK//IGNORE", "UTF-8//IGNORE", ostring)
    end
  end
end