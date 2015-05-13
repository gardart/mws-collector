require 'csv'
gem 'peddler', '= 0.15.0'

require 'active_support/all'
require 'peddler'
require 'logger'
require 'yaml'
require 'date'

config = YAML.load_file( '/opt/scripts/amazon/config/mws.yml' )
config['production']

client_orders = MWS.orders(config['production'])

logger = Logger.new "/var/log/collector/amazon_orders.log"
logger.progname = 'amazon_get_orders'

orders = client_orders.list_orders(created_after: 1.day.ago.end_of_day).parse
#order_list = orders.parse["Orders"]

order_ids=orders["Orders"]["Order"].map{|x| x["AmazonOrderId"]}

orders["Orders"]["Order"].each do |order|
		@amazonorderid 	= order["AmazonOrderId"]
		@purchasedate 	= order["PurchaseDate"]
		puts @amazonorderid
end

#order_ids.each do |x|
#	orderitems =  client_orders.list_order_items(x).parse
#	orderitems["OrderItems"]["OrderItem"].map{|item|
#		puts item["QuantityOrdered"]
#		puts item["SellerSKU"]
#	}
#end
puts "ssssssss"

order_ids.each do |x|
        orderitems =  client_orders.list_order_items(x).parse
	if orderitems.size>1
		for order in orderitems["OrderItems"]["OrderItem"]
			puts " #{order['SellerSKU']} :"
        	end
	else
	puts "aaa"
	end
end

hashes = [{'a' => 'aaaa', 'b' => 'bbbb'}]
#hashes = orders.parse["Orders"]

column_names = hashes.first.keys
s=CSV.generate do |csv|
  csv << column_names
  hashes.each do |x|
    csv << x.values
  end
end
File.write('the_file.csv', s)
