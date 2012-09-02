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
require File.expand_path('../weibo_2', __FILE__)

class SinaApp

  attr_reader :oauth, :request_token, :oauth_verifier
# @param api_key [Object]
# @param api_secret [Object]
  def initialize(api_key="615201284", api_secret="c824df11a6e95ef3be83d60725ec1c0e")

    WeiboOAuth2::Config.api_key = api_key
    WeiboOAuth2::Config.api_secret = api_secret
    WeiboOAuth2::Config.redirect_uri = "http://127.0.0.1:4567/callback"
    @oauth = WeiboOAuth2::Client.new('', '', :ssl => {:ca_path => "D:/Ruby/opentool/openssl/certs"})

    # 1. 用户授权应用，获取授权码
    puts Weibo::Config.to_gbk("拷贝URL到浏览器进行授权:")
    puts @oauth.authorize_url
    key = gets #init_sina_login @oauth.authorize_url
    puts Weibo::Config.to_gbk("请输入获取到的授权码：#{key}")
    @oauth_verifier = key[0,32]
    puts Weibo::Config.to_gbk("获取到的授权码是：#{@oauth_verifier}，#{@oauth_verifier == key[0,32]}")
    @oauth.auth_code.get_token(@oauth_verifier)
  end

  def init_sina_login(url)
    begin
      browser = Watir::Browser.new :firefox
      browser.driver.manage.timeouts.implicit_wait = 10
      browser.goto url
      browser.text_field(:id, "userId").set("03131302@163.com")
      browser.text_field(:id, "passwd").set("the_003131302")
      browser.link(:class, "WB_btn_oauth formbtn_01").click
      browser.link(:class, "WB_btn_oauth formbtn_01").wait_while_present
      Watir::Wait.until { browser.url.include? '127.0.0.1' }
      thekey = browser.url.to_s[browser.url.to_s.length-32, browser.url.to_s.length]
    rescue => err
      puts err
      puts Weibo::Config.to_gbk("请在确认之后输入验证码：")
      a_ulr = gets
    end
  end

  #提交文本型微博内容
  def update(status)
    @oauth.statuses.update(CGI.escape(status))
  end

  #提交图片信息的微博，传入文件路径
  def upload(status, filedir)
    begin
      pic = File.open(filedir)
      @oauth.statuses.upload(CGI.escape(status), pic)
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