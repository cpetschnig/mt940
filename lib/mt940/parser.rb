module MT940

  class BaseError < StandardError; end
  class NoFileGiven < BaseError; end
  class UnknownBank < BaseError; end

  class Parser

    attr_reader :bank

    delegate :transactions, :date, :to => :bank

    def initialize(file)
      file = File.open(file) if file.is_a?(String) 
      if file.is_a?(File) || file.is_a?(Tempfile)
        process(file)
      else
        raise NoFileGiven.new('No file is given!')
      end
    ensure
      file.close if file.respond_to?(:close)
    end

    private

    def process(file)
      bank_class = determine_bank_class(file) || raise(UnknownBank.new('Could not determine bank!'))
      @bank = bank_class.new(file)
      @bank.parse
    end

    def determine_bank_class(file)
      begin
        first_line = file.readline
      end until first_line.strip.present?

      case first_line
      when /^:940:/
        Rabobank
      when /INGBNL/
        Ing
      when /ABNANL/
        Abnamro
      else
        Triodos
      end
    end

  end

end
