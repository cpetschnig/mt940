module MT940

  class NoFileGiven < Exception; end
  class UnknownBank < Exception; end

  class Parser

    attr_accessor :transactions

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
      bank_class = determine_bank_class(file)
      instance = bank_class.new(file)
      instance.parse
      @transactions = instance.transactions
    rescue NoMethodError => exception
      if exception.message == "undefined method `new' for nil:NilClass"
        raise UnknownBank.new('Could not determine bank!')
      else
        raise exception
      end
    end

    def determine_bank_class(file)
      first_line = file.readline
      case first_line
      when /^:940:/
        Rabobank
      when /INGBNL/
        Ing
      when /ABNANL/
        Abnamro
      when /^:20:/
        Triodos
      end
    end

  end

end
