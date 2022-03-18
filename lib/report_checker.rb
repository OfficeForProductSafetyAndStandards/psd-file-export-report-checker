require "json"
require "aws-sdk-s3"
require "slack-notifier"

class ReportChecker
  def self.call(event:, context:)
    bucket_name = event["Records"].first["s3"]["bucket"]["name"]
    key = event["Records"].first["s3"]["object"]["key"]

    s3 = Aws::S3::Client.new(region: "eu-west-2")
    resp = s3.get_object(bucket: bucket_name, key: key)
    csv_file = resp.body.read

    rows = csv_file.split("\n").map { |row| row.split(",") }
    failures_by_row = rows.map { |row| !row.include?("succeeded") || !row.include?("200") }
    any_rows_failed = failures_by_row.include?(true)

    if any_rows_failed
      # the below env variable is defined here: https://eu-west-2.console.aws.amazon.com/lambda/home?region=eu-west-2#/functions/PsdFileExportReportChecker?tab=configure
      webhookurl = ENV["SLACK_WEBHOOK_URL"]
      notifier = Slack::Notifier.new(webhookurl, channel: "#alerts", username: "PsdFileExportReportChecker")
      notifier.ping "Redacted export failed! Bucket: #{bucket_name} Key: #{key}", channel: "#alerts"
    end
  end
end
