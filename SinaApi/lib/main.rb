# encoding: UTF-8
require 'net/http'
require 'rubygems'
require 'httparty'
require File.expand_path('../douban_app_oauth', __FILE__)
require File.expand_path('../sina_app_aouth', __FILE__)
require File.expand_path('../weibo/config', __FILE__)


class CreateInfoTool
  #线程挂起时间(秒)
  @@time = 60

  def initialize
    Weibo::Config.img_dir = "D:/douban_image/"
    Weibo::Config.is_proxy_use = false
    Weibo::Config.is_to_gbk = false
    Weibo::Config.proxy = "http://yangxd:the_my_003131302@nproxy.slof.com:80"
    @app = DoubanApp.new

    #电影
    @data = @app.parse(@app.access_token.get("/movie/subjects?tag=%E7%8A%AF%E7%BD%AA&start-index=240&max-results=10&alt=json").body)
    #书
    @data_books = @app.parse(@app.access_token.get("/book/subjects?tag=%E5%B0%8F%E8%AF%B4&start-index=240&max-results=10&alt=json").body)
    #歌
    @data_musices = @app.parse(@app.access_token.get("/music/subjects?tag=%E6%B0%91%E8%B0%A3&start-index=240&max-results=10&alt=json").body)

    @sina_app = SinaApp.new
  end

  def go
    #    threads = [Thread.new{create_bookes},Thread.new {create_weibo},Thread.new {create_musices}];
    #    threads.each { |t|  t.run;puts "线程启动:#{t.to_s}" }
    #    threads.each { |item| item.join  }
    create_bookes
    create_weibo
    create_musices
  end

  def create_weibo
    @data['entry'].each do |item|
      id_url = @app.moveid(item)
      begin
        move_data = @app.parse(@app.access_token.get("#{id_url}?start-index=1&max-results=1&alt=json").body)
      rescue => err
        puts err
      end
      content = "[给力]电影：名称：#{@app.titlename(move_data)},导演：#{@app.authorname(move_data)},演员表："
      #{@app.cast(move_data)}"#标签：#{app.tag(move_data)}"#简介：#{app.summary(move_data)}\n"
      subcontent = @app.cast(move_data)
      sub_length = 140 - content.length
      sub_length = 0 if sub_length < 0
      content << "#{subcontent[0, sub_length-30]}...}" unless subcontent.nil?
      content << "#{@app.link(move_data)}" unless move_data.nil?
      begin
        puts @sina_app.upload(content, @app.img(move_data))
      rescue => err
        puts err
      ensure
        puts Weibo::Config.to_gbk "结束电影发布:#{@app.titlename(move_data)}"
        sleep(@@time)
      end
    end
  end

  def create_bookes
    @data_books['entry'].each do |item|
      id_url = @app.moveid(item)
      begin
        move_data = @app.parse(@app.access_token.get("#{id_url}?start-index=1&max-results=1&alt=json").body)
      rescue => err
        puts err
      end
      content = "[威武]小说：书名：《#{@app.titlename(move_data)}》,作者：#{@app.authorname(move_data)},简介："
      subcontent = @app.summary(move_data)
      sub_length = 140 - content.length
      sub_length = 0 if sub_length < 0
      content << "#{subcontent[0, sub_length-30]}..." unless subcontent.nil?
      content << "#{@app.link(move_data)}" unless move_data.nil?
      begin
        puts @sina_app.upload(content, @app.img(move_data))
      rescue => err
        puts err
      ensure
        puts Weibo::Config.to_gbk "书籍推荐:《#{@app.titlename(move_data)}》"
        sleep(@@time)
      end
    end
  end

  def create_musices
    @data_musices['entry'].each do |item|
      id_url = @app.moveid(item)
      begin
        move_data = @app.parse(@app.access_token.get("#{id_url}?start-index=1&max-results=1&alt=json").body)
      rescue => err
        puts err
      end
      content = "[神马]好歌：歌名：#{@app.titlename(move_data)},演唱：#{@app.authorname(move_data)},简介："
      subcontent = @app.summary(move_data)
      sub_length = 140 - content.length
      sub_length = 0 if sub_length < 0
      content << "#{subcontent[0, sub_length-30]}..." unless subcontent.nil?
      content << "#{@app.link(move_data)}" unless move_data.nil?
      begin
        puts @sina_app.upload(content, @app.img(move_data))
      rescue => err
        puts err
      ensure
        puts Weibo::Config.to_gbk "歌曲推荐:#{@app.titlename(move_data)}"
        sleep(@@time)
      end
    end
  end

end

CreateInfoTool.new.go