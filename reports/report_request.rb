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

case period
when "daily"
	p_start_date = 1.day.ago.midnight
	p_end_date = 1.day.ago.end_of_day
when "monthly"
	p_start_date = 1.month.ago.beginning_of_month.midnight
        p_end_date = 1.month.ago.end_of_month.end_of_day
end

config_raw = File.read(File.dirname(__FILE__) + "/../config/config.yml")
config_mws = YAML.load(config_raw)[env]['mws']
config_options = YAML.load(config_raw)[env]['options']

client_orders = MWS.orders(config_mws)
client_reports = MWS.reports(config_mws)

logger = Logger.new "/var/log/collector/amazon_reports.log"
logger.progname = 'amazon_report_request'

#$report_type = "_GET_AMAZON_FULFILLED_SHIPMENTS_DATA_"
force_get_report = TRUE

report_request_list = client_reports.get_report_request_list(:report_type_list=>type, :requested_from_date=>1.day.ago.midnight, :report_processing_status_list=>"_DONE_").parse

if report_request_list.count<2 or force_get_report
	#report_request = client_reports.request_report(type, start_date: 1.day.ago.midnight, end_date: 1.day.ago.end_of_day)
	report_request = client_reports.request_report(type, start_date: p_start_date, end_date: p_end_date)
	requestid = report_request.parse["ReportRequestInfo"]["ReportRequestId"]
	reporttype = report_request.parse["ReportRequestInfo"]["ReportType"]
	startdate = report_request.parse["ReportRequestInfo"]["StartDate"]
	enddate = report_request.parse["ReportRequestInfo"]["EndDate"]
	reportid = report_request.parse["ReportRequestInfo"]["GeneratedReportId"]
	#msg=client_reports.get_report_request_list(:report_request_id_list=>50359016543).parse
	msg =  "Report created",requestid,reportid,reporttype,startdate,enddate
	logger.info msg
	puts requestid
else
	report_request_list["ReportRequestInfo"].each do |x|
		@requestid = x["ReportRequestId"]
		@reporttype = x["ReportType"]
		@startdate	= x["StartDate"]
		@enddate	= x["EndDate"]
		@reportid	= x["GeneratedReportId"]
	end 
	msg = "Report Exists",@requestid,@reportid,@reporttype,@startdate,@enddate
	logger.info msg
	puts @requestid
end
