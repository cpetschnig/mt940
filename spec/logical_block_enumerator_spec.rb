require "spec_helper"

describe MT940::LogicalBlockEnumerator do
  it { should be_a Enumerable }
  
  let :lines do
    <<MT940_FILE.lines.map(&:strip)
:20:951110
:25:45050050/76198810
:28:27/01
:60F:C951016DEM84349,74
:61:951017D6800,NCHK16703074
:86:999PN5477SCHECK-NR. 0000016703074
:61:951017D620,3NSTON
:86:999PN0911DAUERAUFTR.NR. 14
:62F:C951017DEM84437,04
MT940_FILE
  end

  let :data_passed_within_each do
    [
        [":20:951110"],
        [":25:45050050/76198810"],
        [":28:27/01"],
        [":60F:C951016DEM84349,74"],
        [":61:951017D6800,NCHK16703074", ":86:999PN5477SCHECK-NR. 0000016703074"],
        [":61:951017D620,3NSTON", ":86:999PN0911DAUERAUFTR.NR. 14"],
        [":62F:C951017DEM84437,04"]
    ]
  end

  subject { described_class.new(lines) }

  describe "#each" do

    it "calls the block 7 times" do
      expect(subject.count).to eq 7
    end

    it "passed the right logical blocks to the Ruby block" do
      expectations_met = 0
      subject.each do |logical_block|
        expect(logical_block.map(&:lines).flatten).to eq data_passed_within_each[expectations_met]
        expectations_met += 1
      end
    end
  end
end
