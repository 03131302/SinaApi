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
      Selenium::WebDriver::Firefox::Binary.path="D:/Program Files/Mozilla Firefox/firefox.exe"
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
    item["directors"].each do |item2|
      author += item2["name"]+","
    end if (!item.nil? && !item["directors"].nil?)
    author[0, author.length-1]
  end

  #获取导演名称
  def authorname_m(item)
    author = ""
    item["author"].each do |item2|
      author += item2["name"]+"," unless item2.nil? && item2["name"].nil?
    end if (!item.nil? && !item["author"].nil?)
    author[0, author.length-1]
  end

  #获取导演名称
  def authorname_book(item)
    author = ""
    item["author"].each do |item2|
      author += item2+"," unless item2.nil?
    end if (!item.nil? && !item["author"].nil?)
    author[0, author.length-1]
  end

  #获取电影名称
  def titlename(item)
    name = item["title"] if (!item.nil? && !item["title"].nil?)
  end

  #获取ID
  def moveid(item)
    item["id"] unless item.nil?
  end

  #获取简介
  def summary(item)
    item["summary"] if (!item.nil? && !item["summary"].nil?)
  end

  #获得标签
  def tag(item)
    tags = ""
    item["genres"].each { |item2| tags += item2+"," } unless item.nil? unless item["genres"].nil?
    tags[0, tags.length-1]
  end

  #演员表
  # @param item [Object]
  def cast(item)
    begin
      cast = ""
      item["casts"].each { |item2| cast += item2["name"]+"," unless item2.nil? && item2["name"].nil? } unless item.nil? && item["casts"].nil?
      cast[0, cast.length-1]
    rescue => err
      puts err
    ensure
      puts "跳过"
    end
  end

  #获取图片
  def img(item)
    dir = ""
    dir=item["images"]["large"] unless item.nil? && item["images"].nil? && item["images"]["large"].nil?
    save_as_local(dir)
  end

  #获取图片
  def img_m(item)
    dir = ""
    dir=item["image"] unless item.nil? && item["image"].nil?
    save_as_local(dir)
  end

  #连接到豆瓣
  def link(item)
    dir = ""
    dir = item["alt"] unless item.nil? && item["alt"].nil?
    dir
  end

  private
  def save_as_local(url_image)
    if Weibo::Config.is_proxy_use then
      web_proxy = Net::HTTP::Proxy('nproxy.slof.com', 80, "yangxd", "my003131302")
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
=begin
Weibo::Config.img_dir = 'D:/douban_image/'
Weibo::Config.is_proxy_use = false
Weibo::Config.is_to_gbk = false
Weibo::Config.proxy = 'http://yangxd:my003131302@nproxy.slof.com:80'
app = DoubanApp.new
temp_data = app.access_token.get("/v2/music/search?tag=%E7%A7%91%E5%B9%BB&start=1&count=2&alt=json").body
puts temp_data
data = app.parse(temp_data)
puts data
data['musics'].each do |item|
  puts item
  id_url = app.moveid(item)
  puts id_url
  temp_body = app.access_token.get("/v2/music/#{id_url}").body
  puts temp_body
  move_data = app.parse(temp_body)
  puts move_data
  puts "导演：#{app.authorname_m(move_data)}"
  puts "名称：#{app.titlename(move_data)}"
  puts "简介：#{app.summary(move_data)}"
  puts "图片：#{app.img_m(move_data)}"
end
=end