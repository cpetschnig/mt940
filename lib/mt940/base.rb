module MT940

  BBAN_PATTERN     = '^\d{10}'
  IBAN_PATTERN     = '[a-zA-Z]{2}[0-9]{2}[a-zA-Z0-9]{4}[0-9]{7}([a-zA-Z0-9]?){0,16}'
  BIC_CODE_PATTERN = MT940::BIC_CODES.values.join('|')
  SEPA_PATTERN     = Regexp.new "(#{IBAN_PATTERN})\\s+(#{BIC_CODE_PATTERN})(.+)$"

  class Base

    attr_accessor :bank, :transactions

    def initialize(file)
      @transactions, @lines = [], []
      @bank = self.class.to_s.split('::').last
      file.readlines.each do |line|
        line.gsub!(%r{^[\r\n]|[\r\n]$}, "")     # drop empty lines, but keep leading/trailing blanks
        next if line.blank?

        line.encode!('UTF-8', 'UTF-8', :invalid => :replace).gsub!(/\s{2,}/,' ')
        @lines << line
      end
    end

    def parse
      LogicalBlockEnumerator.new(@lines).each do |line_block|
        first_line = line_block.first || ""
        tags = first_line.scan(%r{^:(\d{2}F?):}).first
        tag = tags && tags.first
        case tag
          when '25'
            parse_bank_account(first_line)
          when '60F'
            parse_currency(first_line)
          when '61'
            parse_transaction(line_block)
            @transactions << @transaction if @transaction
          when '62F'
            @transaction = nil #Ignore 'eindsaldo'
        end
      end
    end

    private

    def sepa?
      true
    end

    def parse_bank_account(line)
      line.gsub!('.', '')
      @bank_account = $1.gsub(/^0/, '') if line.match(/^:\d{2}:[^\d]*(\d*)/)
    end

    def parse_currency(line)
      @currency = line[12..14]
    end

    def parse_transaction(line_block, pattern = nil)
      pattern ||= %r{^:61:(?<value_date>\d{6})
                          (?<entry_date>\d{4})?
                          (?<debit_credit>C|D)
                          (?<amount_left>\d+),(?<amount_right>\d{0,2})}x

      match = line_block.first.match(pattern)
      if match
        @transaction = create_transaction(match)
        @transaction.date = Date.parse(match["value_date"])
      else
        @transaction = nil
      end

      line_block[1..-1].each { |line| parse_tag_86(line) }

      match
    end

    def parse_tag_86(line)
      if line.match(/^:86:\s?(.*)$/)
        line = $1.strip
        @description, @contra_account = nil, nil
        parse_for_description_and_contra_account(line)
        @transaction.contra_account = @contra_account
        @transaction.description    = @description || line
      end
    end

    def hashify_description(description)
      hash = {}
      description.gsub!(/[^A-Z]\/[^A-Z]/, ' ') #Remove single forward slashes '/', which are not part of a swift code
      description[1..-1].split('/').each_slice(2).each do |first, second|
        hash[first] = second
      end
      hash
    end

    def create_transaction(match)
      type = match["debit_credit"] == "D" ? -1 : 1
      MT940::Transaction.new(bank_account: @bank_account,
                             amount:       type * (match["amount_left"] + "." + match["amount_right"]).to_f,
                             bank:         @bank,
                             currency:     @currency)
    end

    def parse_for_description_and_contra_account(line)
    end

  end

end
