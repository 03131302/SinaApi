# encoding: UTF-8
require 'rubygems'
require 'oauth'
require 'forwardable'
require 'httparty'
require 'hashie'
require 'watir-webdriver'

directory = File.expand_path(File.dirname(__FILE__))
require File.join(directory, 'weibo', 'hashie')
require File.join(directory, 'weibo', 'oauth')
require File.join(directory, 'weibo', 'oauth_hack')
require File.join(directory, 'weibo', 'httpauth')
require File.join(directory, 'weibo', 'request')
require File.join(directory, 'weibo', 'config')
require File.join(directory, 'weibo', 'base')

class SinaApp

  attr_reader :oauth, :request_token, :oauth_verifier
# @param api_key [Object]
# @param api_secret [Object]
  def initialize(api_key="615201284", api_secret="c824df11a6e95ef3be83d60725ec1c0e")

    Weibo::Config.api_key = api_key
    Weibo::Config.api_secret = api_secret
    @oauth = Weibo::OAuth.new(Weibo::Config.api_key, Weibo::Config.api_secret)

    # 1. 获取授权路径
    @request_token = oauth.consumer.get_request_token

    # 2. 用户授权应用，获取授权码
    puts Weibo::Config.to_gbk("拷贝URL到浏览器进行授权:")
    puts @request_token.authorize_url
    key = init_sina_login @request_token.authorize_url
    puts Weibo::Config.to_gbk("请输入获取到的授权码：#{key}")
    @oauth_verifier = key
    puts Weibo::Config.to_gbk("获取到的授权码是：#{@oauth_verifier[0, 6]}，#{@oauth_verifier == key}")

    # 3. 获取授权
    @oauth.authorize_from_request(@request_token, @oauth_verifier[0, 6])
  end

  def init_sina_login(url)
    begin
      browser = Watir::Browser.new :firefox
      browser.goto url
      browser.text_field(:id, "userId").set("03131302@163.com")
      browser.text_field(:id, "passwd").set("the_003131302")
      browser.link(:id, "sub").click
      thekey = browser.span(:class, "fb").text
    rescue => err
      puts err
      puts Weibo::Config.to_gbk("请在确认之后输入验证码：")
      a_ulr = gets
    end
  end

  #提交文本型微博内容
  def update(status)
    Weibo::Base.new(@oauth).update(status)
  end

  #提交图片信息的微博，传入文件路径
  def upload(status, filedir)
    begin
      Weibo::Base.new(@oauth).upload(CGI.escape(status), File.new(filedir, "rb"))
    rescue => err
      puts err
    end
  end

end

#调用例子
#Weibo::Config.proxy = "http://yangxd:0003131302@nproxy.slof.com:80"
#app = SinaApp.new
#puts app.update("哈哈哈哈！")
#puts app.upload("呆呆地","D:/a.GIF")