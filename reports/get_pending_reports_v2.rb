gem 'peddler', '= 0.15.0'

require 'active_support/all'
require 'peddler'
require 'logger'
require 'yaml'
require 'date'
require 'net/smtp'
require 'mail'
require 'fileutils'
require 'optparse'

#  default options
env = "us"
type = "_GET_AMAZON_FULFILLED_SHIPMENTS_DATA_"
period = "daily"
$report_path = config_options['path_to_reports']
$email_report = FALSE

# parse arguments
file = __FILE__
ARGV.options do |opts|
  opts.on("-e", "--env=val", String)   { |val| env = val }
  opts.on("-t", "--type=val", String)   { |val| type = val }
  opts.on("-p", "--period=val", String)   { |val| period = val }
  opts.on_tail("-h", "--help")         { exec "grep ^#/<'#{file}'|cut -c4-" }
  opts.parse!
end

config_raw = File.read(File.dirname(__FILE__) + "/../config/config.yml")
config_mws = YAML.load(config_raw)[env]['mws']
config_options = YAML.load(config_raw)[env]['options']

$client_orders = MWS.orders(config_mws)
$client_reports = MWS.reports(config_mws)

logger = Logger.new "/var/log/collector/amazon_reports.log"
logger.progname = 'amazon_get_report'

unless File.directory?($report_path)
  FileUtils.mkdir_p($report_path)
end

case period
when "daily"
        p_start_date = 1.day.ago.midnight
        p_end_date = 1.day.ago.end_of_day
when "monthly"
        p_start_date = 1.month.ago.beginning_of_month.midnight
        p_end_date = 1.month.ago.end_of_month.end_of_day
end

def get_report(reporttype,reportid,startdate,enddate)
	begin
  	report=$client_reports.get_report(reportid).parse
	rescue Excon::Errors::ServiceUnavailable
  	sleep 1 and retry
	end
	puts report
	File.open("#{$report_path}#{reporttype}_#{reportid}_#{startdate}_#{enddate}.csv", 'w') {|f| f.write(report) }
      	if ($email_report)
		Mail.deliver do
         	from      "actionday@actionday.com"
          	to        "gardar@actionday.com"
          	subject   "Amazon report #{reportid}"
          	body      "#{reporttype}_#{reportid}_#{startdate}_#{enddate}"
          	add_file  "#{$report_path}#{reporttype}_#{reportid}_#{startdate}_#{enddate}.csv"
        	end
	end
end

#$report_type = "_GET_AMAZON_FULFILLED_SHIPMENTS_DATA_"
#$report_type = "_GET_FLAT_FILE_ALL_ORDERS_DATA_BY_ORDER_DATE_"

report_request_list = $client_reports.get_report_request_list(:report_type_list=>ARGV[1], :requested_from_date=>1.month.ago.beginning_of_month, :requested_to_date=>0.month.ago.end_of_month, :report_processing_status_list=>"_DONE_").parse

#report_request_list = $client_reports.get_report_request_list(:report_type_list=>ARGV[1], :requested_from_date=>0.day.ago.midnight, :report_processing_status_list=>"_DONE_").parse

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

