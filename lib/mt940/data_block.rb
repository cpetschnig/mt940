# Main namespace
module MT940

  class DataBlock

    attr_reader :lines

    def initialize(first_line)
      @lines = [first_line]
    end

    def append(line)
      lines << line
    end

    def one_line
      lines.join
    end
    alias :to_s :one_line

    def tag
      lines.first.scan(%r{^:(\d{2}[A-Z]?):}).flatten.first
    end

    def ns_data
      lines.first =~ /^:NS:/ && lines.map { |line|
        data = line.sub(/^:NS:/, "")
        {data[0..1] => data[2..-1]}
      }.reduce(:merge)
    end
  end
end
