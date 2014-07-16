require "spec_helper"

describe MT940::Base do

  let(:fixture_file) { "ing_sepa.txt" }
  let(:filename) { File.expand_path("../../test/fixtures/#{fixture_file}", __FILE__) }
  let(:file) { File.open(filename) }

  subject do
    described_class.new(file)
  end

  around do |example|
    example.run
    file.close
  end

  describe "#parse" do

    shared_examples_for "any tag style" do

      it "passes a whole array of lines for one transaction to the create_transaction method" do
        expect(subject).to receive(:create_transaction).exactly(expected_count).times.and_return MT940::Transaction.new
        subject.parse
      end

      it "sets the right date" do
        subject.parse
        expect(subject.date).to eq expected_date
      end

      it "sets the right start balance" do
        subject.parse
        expect(subject.start_balance).to eq expected_start_balance
      end
    end

    context "when handling :86: tags" do
      let(:fixture_file) { "ing_sepa.txt" }
      let(:expected_count) { 9 }
      let(:expected_date) { Date.parse("2012-08-10") }
      let(:expected_start_balance) { 68.20 }

      it_behaves_like "any tag style"
    end

    context "when handling :NS: tags" do
      let(:fixture_file) { "with_NS_tags.txt" }
      let(:expected_count) { 17 }
      let(:expected_date) { Date.parse("2013-04-26") }
      let(:expected_start_balance) { 505.25 }

      it_behaves_like "any tag style"
    end
  end
end
