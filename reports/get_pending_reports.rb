gem 'peddler', '= 0.15.0'

require 'active_support/all'
require 'peddler'
require 'logger'
require 'yaml'
require 'date'
require 'net/smtp'
require 'mail'

config = YAML.load_file( File.dirname(__FILE__) + "/../config/mws.yml")
config['production']
#puts config['production']

client_orders = MWS.orders(config['production'])
$client_reports = MWS.reports(config['production'])
$report_path = "/opt/amazon/reports/us/daily/"

logger = Logger.new "/var/log/collector/amazon_reports.log"
logger.progname = 'amazon_get_report'

def get_report(reporttype,reportid,startdate,enddate)
	begin
        report=$client_reports.get_report(reportid).parse
        rescue Excon::Errors::ServiceUnavailable
        sleep 1 and retry
        end
	puts report
	File.open("#{$report_path}#{reporttype}_#{reportid}_#{startdate}_#{enddate}.csv", 'w') {|f| f.write(report) }
      	Mail.deliver do
          from      "actionday@actionday.com"
          to        "actionday@actionday.com"
          subject   "Amazon report #{reportid}"
          body      "#{reporttype}_#{reportid}_#{startdate}_#{enddate}"
          add_file  "#{$report_path}#{reporttype}_#{reportid}_#{startdate}_#{enddate}.csv"
        end
end

#$report_type = "_GET_AMAZON_FULFILLED_SHIPMENTS_DATA_"
#$report_type = "_GET_FLAT_FILE_ALL_ORDERS_DATA_BY_ORDER_DATE_"

report_request_list = $client_reports.get_report_request_list(:report_type_list=>ARGV[0], :requested_from_date=>0.day.ago.midnight, :report_processing_status_list=>"_DONE_").parse

#report=client_reports.get_report($report_id).parse
#puts report

if (report_request_list["ReportRequestInfo"][0] != nil)
	report_request_list["ReportRequestInfo"].each do |x|
               	@requestid      = x["ReportRequestId"]
               	@reporttype     = x["ReportType"]
               	@startdate      = x["StartDate"]
               	@enddate        = x["EndDate"]
               	@reportid       = x["GeneratedReportId"]
		msg = "Report Ready: RequestId=>#{@requestid} : ReportId=>#{@reportid} : #{@reporttype} : #{@startdate} : #{@enddate}"
		puts msg
		logger.info msg
		puts get_report(@reporttype,@reportid,@startdate,@enddate)
        end
else
	@requestid      = report_request_list["ReportRequestInfo"]["ReportRequestId"]
        @reporttype     = report_request_list["ReportRequestInfo"]["ReportType"]
        @startdate      = report_request_list["ReportRequestInfo"]["StartDate"]
        @enddate        = report_request_list["ReportRequestInfo"]["EndDate"]
        @reportid       = report_request_list["ReportRequestInfo"]["GeneratedReportId"]
	msg = "Report Ready: RequestId=>#{@requestid} : ReportId=>#{@reportid} : #{@reporttype} : #{@startdate} : #{@enddate}"
        puts msg
        logger.info msg
	puts get_report(@reporttype,@reportid,@startdate,@enddate)
end

