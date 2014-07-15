# Main namespace
module MT940
  # Represents one logical block of MT940 source lines.
  # Example:
  #
  #    :20:MPBZ                                                           # one data block
  #
  #    :25:0001234567                                                     # one data block
  #
  #    :28C:000                                                           # one data block
  #
  #    :60F:C100722EUR0,00                                                # one data block
  #
  #    :61:100722D25,03NOV NONREF                                         # one data block
  #    :86: RC AFREKENING BETALINGSVERKEER                                #      |
  #    BETREFT REKENING 4715589 PERIODE: 01-10-2010 / 31-12-2010          #      V
  #    ING Bank N.V. tarifering ING                                       # `til here
  #
  #    :61:100722D3,03NOV NONREF                                          # one data
  #    :86:0111111111 GPSEOUL SPOEDBETALING	MPBZS1016000047 GPSEOUL       #   block
  #
  class DataBlock

    attr_reader :lines

    def initialize(first_line)
      @lines = [first_line]
    end

    # append another line when building the object
    def append(line)
      lines << line
    end

    # returns the whole block as a single string without newlines
    def one_line
      lines.join
    end
    alias :to_s :one_line

    # returns the MT940 tag in the very beginning of the block
    def tag
      lines.first.scan(%r{^:(\d{2}[A-Z]?):}).flatten.first
    end

    # returns the whole :NS: data as hash with annotated line numbers as keys
    def ns_data
      ns_line_index = lines.index { |line| line =~ /^:NS:/ }
      ns_line_index && lines[ns_line_index..-1].map { |line|
        data = line.sub(/^:NS:/, "")
        {data[0..1] => data[2..-1]}
      }.reduce(:merge)
    end
  end
end
