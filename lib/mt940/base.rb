require 'charlock_holmes'

module MT940

  BBAN_PATTERN     = '^\d{10}'
  IBAN_PATTERN     = '[a-zA-Z]{2}[0-9]{2}[a-zA-Z0-9]{4}[0-9]{7}([a-zA-Z0-9]?){0,16}'
  BIC_CODE_PATTERN = MT940::BIC_CODES.values.join('|')
  SEPA_PATTERN     = Regexp.new "(#{IBAN_PATTERN})\\s+(#{BIC_CODE_PATTERN})(.+)$"

  class Base

    attr_reader :bank, :date, :start_balance, :transactions

    def initialize(file)
      @transactions, @lines = [], []
      @bank = self.class.to_s.split('::').last

      content = file.read

      detection = CharlockHolmes::EncodingDetector.detect(content)
      content = CharlockHolmes::Converter.convert content, detection[:encoding], 'UTF-8'

      return if content.blank?

      content = content.gsub("\r\n", "\n").gsub("\r", "\n") rescue content

      # empty lines are dropped by split
      @lines = content.split("\n").map { |line| line.encode(:invalid => :replace).gsub(/\s{2,}/,' ') }
    end

    def parse
      LogicalBlockEnumerator.new(@lines).each do |line_block|
        first_data_block = line_block.first
        tag = first_data_block && first_data_block.tag
        case tag
          when '25'
            parse_bank_account(first_data_block)
          when '60F'
            parse_statement_info(first_data_block)
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

    def parse_bank_account(data_block)
      line = data_block.lines.first
      line.gsub!('.', '')
      @bank_account = $1.gsub(/^0/, '') if line.match(/^:\d{2}:[^\d]*(\d*)/)
    end

    def parse_statement_info(data_block)
      line = data_block.lines.first
      @currency = line[12..14]
      @date = Date.parse(line[6..12])
      @start_balance = line[15..-1].sub(",", ".").to_f
    end

    def parse_transaction(data_blocks, pattern = nil)
      pattern ||= %r{^:61:(?<value_date>\d{6})
                          (?<entry_date>\d{4})?
                          (?<debit_credit>C|D)
                          (?<amount_left>\d+),(?<amount_right>\d{0,2})}x
      match = data_blocks.first.one_line.match(pattern)
      if match
        @transaction = create_transaction(match)
        @transaction.date = Date.parse(match["value_date"])
      else
        @transaction = nil
      end

      data_blocks[1..-1].each { |line| parse_tag_86(line) }

      data_blocks[1..-1].each { |line| parse_tag_ns(line) }

      match
    end

    def parse_tag_86(data_block)
      line = data_block.one_line
      if line.match(/^:86:\s?(.*)$/)
        line = $1.strip
        @description, @contra_account = nil, nil
        parse_for_description_and_contra_account(line)
        @transaction.contra_account = @contra_account
        @transaction.description    = @description || line
      end
    end

    def parse_tag_ns(data_block)
      ns_data = data_block.ns_data
      return unless ns_data
      @transaction.description = ns_data["17"]
      @text = (1..14).map { |number| "%02d" % number }.map { |number| ns_data[number] }.join(" ")
      @transaction.contra_account = ns_data["33"]
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
