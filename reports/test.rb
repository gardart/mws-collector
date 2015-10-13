gem 'peddler', '= 0.15.0'

require 'active_support/all'
require 'peddler'
require 'logger'
require 'yaml'

require 'optparse'

#  default options
env = "us"
type = "_GET_AMAZON_FULFILLED_SHIPMENTS_DATA_"
period = "daily"

# parse arguments
file = __FILE__
ARGV.options do |opts|
  opts.on("-e", "--env=val", String)   { |val| env = val }
  opts.on("-t", "--type=val", String)   { |val| type = val }
  opts.on("-p", "--period=val", String)   { |val| period = val }
  opts.on_tail("-h", "--help")         { exec "grep ^#/<'#{file}'|cut -c4-" }
  opts.parse!
end


config_raw = File.read("/opt/scripts/amazon" + "/config/config.yml")
config_mws = YAML.load(config_raw)[env]['mws']
#config_options = YAML.load(config_raw)[ARGV[0]]['options']
puts config_mws
##config_options = YAML.load(config_raw)[ARGV[0]]['options']

#$client_orders = MWS.orders(config_mws)
#$client_reports = MWS.reports(config_mws)

#logger = Logger.new "/var/log/collector/amazon_reports.log"
#logger.progname = 'amazon_report_request'

#$report_type = "_GET_AMAZON_FULFILLED_SHIPMENTS_DATA_"
force_get_report = TRUE

warn "test : #{env.inspect}"
