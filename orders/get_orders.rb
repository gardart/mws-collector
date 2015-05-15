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

order_ids=orders["Orders"]["Order"].map{|x| x["AmazonOrderId"]}
puts "Amazon order ids created after #{1.day.ago.end_of_day}"
orders["Orders"]["Order"].each do |order|
		@amazonorderid 	= order["AmazonOrderId"]
		@purchasedate 	= order["PurchaseDate"]
		puts "#{@amazonorderid};#{@purchasedate}"
end

puts "Order Items:"
puts ""

order_ids.each do |x|
        orderitems =  client_orders.list_order_items(x).parse
	if (orderitems["OrderItems"]["OrderItem"][0] != nil)
		orderitems["OrderItems"]["OrderItem"].each do |order|
			puts "#{order['SellerSKU']};#{order['QuantityOrdered']}"
			
        	end
	else
	order = orderitems["OrderItems"]["OrderItem"]
	puts "#{order['SellerSKU']};#{order['QuantityOrdered']}"
	end
end

hashes = [{'a' => 'aaaa', 'b' => 'bbbb'}]

column_names = hashes.first.keys
s=CSV.generate do |csv|
  csv << column_names
  hashes.each do |x|
    csv << x.values
  end
end
File.write('the_file.csv', s)
