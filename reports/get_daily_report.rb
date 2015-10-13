gem 'peddler', '= 0.15.0'

require 'active_support/all'
require 'peddler'
require 'logger'
require 'yaml'
require 'date'

config = YAML.load_file( '/opt/scripts/amazon/config/mws.yml' )
config['production']
#puts config['production']

client_orders = MWS.orders(config['production'])
client_reports = MWS.reports(config['production'])

logger = Logger.new "/var/log/collector/amazon_reports.log"
logger.progname = 'amazon_get_report'

## Test connection
#client_orders.get_service_status.parse

#$report_type = "_GET_AMAZON_FULFILLED_SHIPMENTS_DATA_"

report_request_list = client_reports.get_report_request_list(:report_type_list=>ARGV[0], :requested_from_date=>0.day.ago.midnight, :report_processing_status_list=>"_DONE_").parse
if report_request_list.count<2
	msg = "No report available"
	logger.error msg
else
	report_request_list["ReportRequestInfo"].each do |x|
		@requestid 	= x["ReportRequestId"]
		@reporttype 	= x["ReportType"]
		@startdate	= x["StartDate"]
		@enddate	= x["EndDate"]
		@reportid	= x["GeneratedReportId"]
#		puts " #@reporttype :  #@requestid : #@reportid : #@startdate : #@enddate "
		if DateTime.parse(@startdate) == 1.day.ago.midnight && DateTime.parse(@enddate) <= 1.day.ago.end_of_day
		#	puts " #@reporttype :  #@requestid : #@reportid : #@startdate : #@enddate "
			$report_id = @reportid 
		end
	end 
#	puts $report_id
#	msg = "Report Exists",@requestid,@reportid,@reporttype,@startdate,@enddate
#	logger.info msg
#	puts @requestid
end

report=client_reports.get_report($report_id).parse
puts report
