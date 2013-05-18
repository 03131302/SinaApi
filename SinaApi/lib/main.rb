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
    Weibo::Config.img_dir = '/home/my03131302/Ruby/douban_image/'
    Weibo::Config.is_proxy_use = false
    Weibo::Config.is_to_gbk = false
    Weibo::Config.proxy = 'http://yangxd:my003131302@nproxy.slof.com:80'
#=begin
    @app = DoubanApp.new
#电影
    @data = @app.parse(@app.access_token.get("/v2/movie/search?tag=%E7%BA%AA%E5%BD%95%E7%89%87&start=1&count=10&alt=json").body)
#书
    @data_books = @app.parse(@app.access_token.get("/v2/book/search?tag=%E6%BC%AB%E7%94%BBstart=1&count=10&alt=json").body)
#歌
    @data_musices = @app.parse(@app.access_token.get("/v2/music/search?tag=%E7%94%B5%E5%BD%B1%E5%8E%9F%E5%A3%B0&start=1&count=10&alt=json").body)
#=end
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
    puts @data
    @data['subjects'].each do |item|
      id_url = @app.moveid(item)
      begin
        temp_body = @app.access_token.get("/v2/movie/subject/#{id_url}").body
        move_data = @app.parse(temp_body)
      rescue => err
        puts err
      end
      content = "[给力]纪录片：名称：#{@app.titlename(move_data)},导演：#{@app.authorname(move_data)},演员表："
      #{@app.cast(move_data)}"#标签：#{app.tag(move_data)}"#简介：#{app.summary(move_data)}\n"
      subcontent = @app.cast(move_data)
      sub_length = 140 - content.length
      sub_length = 0 if sub_length < 0
      content << "#{subcontent[0, sub_length-30]}..." unless subcontent.nil?
      content << "#{@app.link(move_data)}" unless move_data.nil?
      begin
        puts content
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
    @data_books['books'].each do |item|
      id_url = @app.moveid(item)
      begin
        temp_body = @app.access_token.get("/v2/book/#{id_url}").body
        puts temp_body
        move_data = @app.parse(temp_body)
        puts move_data
      rescue => err
        puts err
      end
      content = "[威武]漫画：书名：《#{@app.titlename(move_data)}》,作者：#{@app.authorname_book(move_data)},简介："
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
    @data_musices['musics'].each do |item|
      id_url = @app.moveid(item)
      begin
        move_data = @app.parse(@app.access_token.get("/v2/music/#{id_url}?alt=json").body)
      rescue => err
        puts err
      end
      content = "[神马]好歌：歌名：#{@app.titlename(move_data)},演唱：#{@app.authorname_m(move_data)},简介："
      subcontent = @app.summary(move_data)
      sub_length = 140 - content.length
      sub_length = 0 if sub_length < 0
      content << "#{subcontent[0, sub_length-30]}..." unless subcontent.nil?
      content << "#{@app.link(move_data)}" unless move_data.nil?
      begin
        puts @sina_app.upload(content, @app.img_m(move_data))
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
