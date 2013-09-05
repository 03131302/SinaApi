# encoding: UTF-8
module Weibo
  module Config

    def self.proxy=(val)
      @@proxy = val
    end

    def self.proxy
      @@proxy
    end

    def self.is_proxy_use=(val)
      @@is_proxy_use = val
    end

    def self.is_proxy_use
      @@is_proxy_use
    end

    def self.img_dir=(val)
      @@img_dir = val
    end

    def self.img_dir
      @@img_dir
    end

    def self.is_to_gbk=(val)
      @@is_to_gbk = val
    end

    def self.is_to_gbk
      @@is_to_gbk
    end

    def self.api_key=(val)
      @@api_key = val
    end

    def self.api_key
      @@api_key
    end

    def self.api_secret=(val)
      @@api_secret = val
    end

    def self.api_secret
      @@api_secret
    end

    # @param ostring [Object]
    def self.to_gbk(ostring)
      if  Weibo::Config.is_to_gbk then
        ostring.encode Encoding::GBK
      else
        ostring
      end
    end
  end
end