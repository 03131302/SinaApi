# encoding: UTF-8
require 'rubygems'
require 'oauth'
require 'httparty'
require 'crack'
require 'watir-webdriver'

directory = File.expand_path(File.dirname(__FILE__))
require File.join(directory, 'weibo', 'config')

class DoubanApp

  attr_reader :consumer, :request_token, :access_token
# @param [Object] api_key
# @param [Object] api_secret
  def initialize(api_key="02e668ada1bc653408b33a08e5352f9c", api_secret="13828a9a245f335f")
    douban_api_key = api_key
    douban_api_key_secret = api_secret
    config_init = {
        :site => "http://www.douban.com",
        :request_token_path => "/service/auth/request_token",
        :access_token_path => "/service/auth/access_token",
        :authorize_path => "/service/auth/authorize",
        :signature_method => "HMAC-SHA1",
        :scheme => :header,
        :realm => "http://10.207.9.11:8090/eip"
    }
    if Weibo::Config.is_proxy_use then
      config_init.store(:proxy, Weibo::Config.proxy)
    end

    @consumer = OAuth::Consumer.new(
        douban_api_key,
        douban_api_key_secret,
        config_init
    )

    # 1. 获取 request_token
    @request_token = @consumer.get_request_token

    # 2. 授权
    puts Weibo::Config.to_gbk("拷贝URL到浏览器进行授权:")
    puts @request_token.authorize_url
    a = init_douban_login @request_token.authorize_url
    #程序中断等待授权完成
    puts Weibo::Config.to_gbk("请等待授权完成之后输入ok！")
    puts Weibo::Config.to_gbk("授权已经完成#{a}")

    # 3. 获取 access_token
    @access_token = @request_token.get_access_token
    config_init_pa = {
        :site => "http://api.douban.com",
        :scheme => :header,
        :signature_method => "HMAC-SHA1",
        :realm => "http://10.207.9.11:8090/eip",
        #:proxy => Weibo::Config.proxy
    }
    if Weibo::Config.is_proxy_use then
      config_init_pa.store(:proxy, Weibo::Config.proxy)
    end
    @access_token = OAuth::AccessToken.new(
        OAuth::Consumer.new(
            douban_api_key,
            douban_api_key_secret,
            config_init_pa
        ),
        @access_token.token,
        @access_token.secret
    )
  end

  def init_douban_login(url)
    begin
      browser = Watir::Browser.new :firefox
      browser.goto url
      browser.link(:text, "登录").click
      browser.text_field(:id, "email").set("03131302@163.com")
      browser.text_field(:id, "password").set("the003131302")
      browser.button(:name, "user_login").click
      browser.button(:name, "confirm").click
      browser.url
    rescue => err
      puts err
      puts Weibo::Config.to_gbk("请在确认之后输入ok")
      a_ulr = gets
    end
  end

# @param response [Object]
  def parse(response)
    Crack::JSON.parse(response)
  end

  #获取导演名称
  def authorname(item)
    author = ""
    item["author"].each { |item2| author += item2["name"]["$t"]+"," } if (!item.nil? && !item["author"].nil?)
    author[0, author.length-1]
  end

  #获取电影名称
  def titlename(item)
    name = item["title"]["$t"] if (!item.nil? && !item["title"].nil?)
    zh_name = ""
    item["db:attribute"].each { |item2| zh_name = item2["$t"] if ("aka" == item2["@name"] && "zh_CN" == item2["@lang"]) } unless item.nil?
    ("" == zh_name or zh_name.nil?) ? name : "#{zh_name}(#{name})"
  end

  #获取ID
  def moveid(item)
    item["id"]["$t"] unless item.nil?
  end

  #获取简介
  def summary(item)
    item["summary"]["$t"] if (!item.nil? && !item["summary"].nil?)
  end

  #获得标签
  def tag(item)
    tags = ""
    item["db:tag"].each { |item2| tags += item2["@name"]+"," } unless item.nil?
    tags[0, tags.length-1]
  end

  #演员表
  # @param item [Object]
  def cast(item)
    cast = ""
    item["db:attribute"].each { |item2| cast += item2["$t"]+"," if "cast" == item2["@name"] } unless item.nil?
    cast[0, cast.length-1]
  end

  #获取图片
  def img(item)
    dir = ""
    item["link"].each { |item2| dir = item2["@href"] if "image" == item2["@rel"] } unless item.nil?
    save_as_local(dir)
  end

  #连接到豆瓣
  def link(item)
    dir = ""
    item["link"].each { |item2| dir = item2["@href"] if "alternate" == item2["@rel"] } unless item.nil?
    dir
  end

  private
  def save_as_local(url_image)
    if Weibo::Config.is_proxy_use then
      web_proxy = Net::HTTP::Proxy('nproxy.slof.com', 80, "yangxd", "the_my_003131302")
    else
      web_proxy = Net::HTTP
    end
    url = URI.parse(url_image)
    dir_name = ""
    web_proxy.start(url.host, url.port) do |http|
      Dir.mkdir(Weibo::Config.img_dir) unless File.exist?(Weibo::Config.img_dir)
      dir_name = "#{Weibo::Config.img_dir}#{File.basename(url_image)+Time.now.strftime("%Y%m%d%H%M%S")+File.extname(url_image)}"
      req = Net::HTTP::Get.new(url.path)
      new_image = File.new(dir_name, "wb")
      new_image.puts http.request(req).body
      new_image.close
    end
    dir_name
  end

end
#API测试，检索电影
#Weibo::Config.proxy = "http://yangxd:0003131302@nproxy.slof.com:80"
#app = DoubanApp.new
#data = app.parse(app.access_token.get("/movie/subjects?tag=%E7%A7%91%E5%B9%BB&start-index=1&max-results=1&alt=json").body)
#data['entry'].each do |item|
#  id_url = app.moveid(item)
#  move_data = app.parse(app.access_token.get("#{id_url}?start-index=1&max-results=2&alt=json").body)
#  puts "导演：#{app.authorname(move_data)}"
#  puts "名称：#{app.titlename(move_data)}"
#  puts "演员表：#{app.cast(move_data)}"
#  puts "标签：#{app.tag(move_data)}"
#  puts "简介：#{app.summary(move_data)}"
#  puts "图片：#{app.img(move_data)}"
#end