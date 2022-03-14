require 'report_checker.rb'
require 'rspec.rb'

describe 'ReportChecker' do
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
              "size" => 14772,
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

  let(:aws_double)  { "aws_double" }
  let(:resp_double) { "resp_double" }

  before do
    allow(Aws::S3::Client).to receive(:new) { aws_double }
    allow(aws_double).to receive(:get_object) { resp_double }
    allow(resp_double).to receive_message_chain(:body, :read) { csv }
  end

  context "when the report has failures" do
    let(:csv) { csv_with_failures }

    it "returns true" do
      result = ReportChecker.call(event: event, context: nil)
      expect(result).to eq true
    end
  end

  context "when report has no failures" do
    let(:csv) { csv_without_failures }

    it "returns false" do
      result = ReportChecker.call(event: event, context: nil)
      expect(result).to eq false
    end
  end

end
