require "spec_helper"

describe MT940::DataBlock do

  let(:first_line) { ":99:this is the first line" }
  let(:another_line) { ":XY:some other line" }
  let(:ns_lines) { <<-EOS.lines.map(&:strip)
                   :NS:01the first row
                   07the data of row 7
                   71Germany advances to the WC final by that score
                   EOS
  }

  subject { described_class.new(first_line) }

  describe "#append" do
    it "appends to the lines" do
      subject.append(another_line)
      expect(subject.lines).to eq [first_line, another_line]
    end
  end

  describe "#one_line" do
    it "returns all lines as one string" do
      subject.append(another_line)
      expect(subject.one_line).to eq (first_line << another_line)
    end
  end

  describe "#tag" do
    it "returns the MT940 tag of the first line" do
      expect(subject.tag).to eq "99"
    end
  end

  describe "#ns_data" do
    context "when there is no NS data" do
      it "returns nil" do
        expect(subject.ns_data).to be_nil
      end
    end

    context "when there is some NS data" do
      before { ns_lines.each { |line| subject.append(line) } }

      it "returns a hash with line numbers as keys" do
        expect(subject.ns_data["01"]).to eq "the first row"
        expect(subject.ns_data["02"]).to be_nil
        expect(subject.ns_data["07"]).to eq "the data of row 7"
        expect(subject.ns_data["71"]).to eq "Germany advances to the WC final by that score"
      end
    end
  end
end
