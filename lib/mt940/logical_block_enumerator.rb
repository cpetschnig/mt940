# Main namespace
module MT940
  # Enumerate of the the lines of the MT940 file and pass logical blocks to the Ruby block
  #
  # Example:
  #
  #    :20:951110
  #    :25:45050050/76198810
  #    :28:27/01
  #    :60F:C951016DEM84349,74
  #    :61:951017D6800,NCHK16703074
  #    :86:999PN5477SCHECK-NR. 0000016703074
  #    :61:951017D620,3NSTON
  #    :86:999PN0911DAUERAUFTR.NR. 14
  #    :62F:C951017DEM84437,04
  #
  #    Data passed to the block in the `each` loop:
  #
  #    [":20:951110"]
  #    [":25:45050050/76198810"]
  #    [":28:27/01"]
  #    [":60F:C951016DEM84349,74"]
  #    [":61:951017D6800,NCHK16703074", ":86:999PN5477SCHECK-NR. 0000016703074"]
  #    [":61:951017D620,3NSTON",        ":86:999PN0911DAUERAUFTR.NR. 14"]
  #    [":62F:C951017DEM84437,04"]
  #
  # (:86: is always additional data to :61:, so it should be handled together)
  class LogicalBlockEnumerator
    include Enumerable

    attr_reader :lines

    def initialize(lines)
      @lines = lines
    end

    # Iterate over the lines and call the Ruby block with each logical block
    def each(&block)
      remaining_lines = @lines

      begin
        logical_block, remaining_lines = next_logical_block(remaining_lines)
        block.call(logical_block)
      end until remaining_lines.blank?

      @lines
    end

    private

    def start_of_block?(line)
      line =~ %r{^(:\d{2}[A-Z]?:|:?940:?|0000\s|ABNA)}
    end

    def end_of_block?(line)
      line =~ %r{^:\d{2}[A-Z]?:} && line !~ %r{^:(86|NS):}
    end

    def next_logical_block(lines)
      head = []
      body = []
      remaining_lines = lines

      remaining_lines.each do |line|
        break if start_of_block?(line)
        head << line
      end

      remaining_lines = remaining_lines[head.length..-1]

      in_body = false
      remaining_lines.each do |line|
        if in_body
          break if end_of_block?(line)
        else
          in_body = true
        end

        if start_of_block?(line) || body.empty?
          body << line
        else
          body.last << line
        end
      end

      remaining_lines = remaining_lines[body.length..-1]

      [body, remaining_lines]
    end
  end
end
