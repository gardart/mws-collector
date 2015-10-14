gem 'peddler', '= 0.15.0'

require 'active_support/all'
require 'peddler'
require 'logger'
require 'yaml'

config = YAML.load_file( File.dirname(__FILE__) + "/../config/mws.yml")

client_orders = MWS.orders(config[ARGV[0]])
client_reports = MWS.reports(config[ARGV[0]])

logger = Logger.new "/var/log/collector/amazon_reports.log"
logger.progname = 'amazon_report_request'

## Test connection
#client_orders.get_service_status.parse

#$report_type = "_GET_AMAZON_FULFILLED_SHIPMENTS_DATA_"
force_get_report = TRUE

report_request_list = client_reports.get_report_request_list(:report_type_list=>ARGV[1], :requested_from_date=>1.day.ago.midnight, :report_processing_status_list=>"_DONE_").parse
if report_request_list.count<2 or force_get_report
	report_request = client_reports.request_report(ARGV[1], start_date: 1.day.ago.midnight, end_date: 1.day.ago.end_of_day)
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
