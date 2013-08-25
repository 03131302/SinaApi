require 'sinatra'

class MyServer < Sinatra::Base
  get '/callback' do
    "#{params[:name]}"
  end

  get '/' do
    'Hello'
  end

  def self.run
    run! if app_file == $0
  end
end
