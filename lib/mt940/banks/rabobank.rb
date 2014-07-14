class MT940::Rabobank < MT940::Base

  private

  def parse_bank_account(data_block)
    @line = data_block.lines.first
    @line.gsub!('.','')
    if @line.match(Regexp.new ":25:(#{MT940::IBAN_PATTERN})")
      @bank_account = $1
      @sepa = true
    else
      @bank_account = $1.gsub(/^0/,'') if @line.match(/^:\d{2}:[^\d]*(\d*)/)
    end
  end

  def parse_transaction(data_blocks, pattern = nil)
    match = super(data_blocks, %r{^:61:(?<value_date>\d{6})
                                       (?<debit_credit>C|D)
                                       (?<amount_left>\d+),(?<amount_right>\d{0,2})
                                       \w{4}\w{1}
                                       (?<contra_1>\d{9}|NONREF|EREF)
                                       (?<contra_2>.*)$}x)
    if match
      if @sepa
        @transaction.contra_account = match["contra_2"].strip
      else
        @transaction.contra_account = match["contra_1"].strip
        @transaction.contra_account_owner = match["contra_2"].strip
      end
    end
  end

  def parse_tag_86(data_block)
    line = data_block.one_line
    if line.match(/^:86:(.*)$/)
      line = $1.strip
      @sepa ? determine_description_after_sepa(line) : determine_description_before_sepa(line)
      @transaction.description = @description.strip
    end
  end

  def determine_description_before_sepa(line)
    if @description.nil? 
      @description = line
    else
      @description += ' ' + line
    end
  end

  def determine_description_after_sepa(line)
    hash = hashify_description(line)
    @description = ''
    @description += hash['NAME'] if hash['NAME']
    @description += ' '
    @description += hash['REMI'] if hash['REMI']
  end

end
