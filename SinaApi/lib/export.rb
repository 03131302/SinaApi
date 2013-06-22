require 'net/http'
require 'net/https'


url = URI.parse('https://gitcafe.com/')
http = Net::HTTP.new(url.host, url.port)
http.use_ssl = true if url.scheme == 'https'
http.verify_mode = OpenSSL::SSL::VERIFY_NONE #这个也很重要
request = Net::HTTP::Get.new(url.path)
puts http.request(request).body
