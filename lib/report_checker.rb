require "json"
require "aws-sdk"
require "aws-sdk-core"
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

    any_rows_failed

    # if any_rows_failed == true
    #   webhookurl = ENV["WEBHOOK_URL"]
    #   notifier = Slack::Notifier.new(webhookurl, channel: "@macphersonkd", username: "notifier")
    #   notifier.ping "The redacted export has failures", channel: "@macphersonkd"
    # end
  end
end
