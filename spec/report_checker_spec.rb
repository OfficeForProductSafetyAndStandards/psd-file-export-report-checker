require "report_checker"
require "rspec"

describe "ReportChecker" do
  let!(:event) do
    {
      "Records" => [
        {
          "s3" => {
            "s3SchemaVersion" => "1.0",
            "configurationId" => "XXXX",
            "bucket" => {
              "name" => "psd",
              "ownerIdentity" => {
                "principalId" => "XXXXXXX"
              },
              "arn" => "arn:aws:s3:::psd"
            },
            "object" => {
              "key" => "reports/job-XXX.csv",
              "size" => 14_772,
              "eTag" => "XXXXXX",
              "sequencer" => "XXXXXX"
            }
          }
        }
      ]
    }
  end

  let(:csv_without_failures) do
    "xyzxyz,Fqzv6q8Adycwndq0kmne36a2qo,,succeeded,200,,Successful\r\nxyzxyz,Fqzv6q8AdFqzv6q8Ad,,succeeded,200,,Successful\r\n"
  end

  let(:csv_with_failures) do
    "xyzxyz,Fqzv6q8Adycwndq0kmne36a2qo,,failed,400,,Failure\r\nxyzxyz,Fqzv6q8AdFqzv6q8Ad,,succeeded,200,,Successful\r\n"
  end

  let(:aws_double) { "aws_double" }
  let(:response_double) { "response_double" }
  let(:slack_notifier_double) { "slack_notifier_double" }

  before do
    allow(Aws::S3::Client).to receive(:new) { aws_double }
    allow(aws_double).to receive(:get_object) { response_double }
    allow(response_double).to receive_message_chain(:body, :read) { csv }
    ENV["SLACK_WEBHOOK_URL"] = "https://www.somefakeandrandomurl.com"
    allow(Slack::Notifier).to receive(:new) { slack_notifier_double }
  end

  context "when the report has failures" do
    let(:csv) { csv_with_failures }

    it "triggers slack notifier to send a slack message" do
      expect(slack_notifier_double).to receive(:ping).with("Redacted export failed! Bucket: psd Key: reports/job-XXX.csv")
      ReportChecker.call(event: event, context: nil)
    end
  end

  context "when report has no failures" do
    let(:csv) { csv_without_failures }

    it "does not trigger slack notifier to send a slack message" do
      expect(slack_notifier_double).not_to receive(:ping)
      ReportChecker.call(event: event, context: nil)
    end
  end

  context "when there is an exception" do
    it "triggers slack notifier to send info about the exception and raises the error" do
      allow(Aws::S3::Client).to receive(:new) { raise StandardError }
      expect(slack_notifier_double).to receive(:ping).with("ReportChecker Exception. StandardError StandardError")
      expect { ReportChecker.call(event: event, context: nil) }.to raise_error
    end
  end
end
