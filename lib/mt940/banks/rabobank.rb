class MT940::Rabobank < MT940::Base

  private

  def parse_tag_25
    @line.gsub!('.','')
    if @line.match(Regexp.new ":25:(#{MT940::IBAN_PATTERN})")
      @bank_account = $1
      @sepa = true
    else
      @bank_account = $1.gsub(/^0/,'') if @line.match(/^:\d{2}:[^\d]*(\d*)/)
    end
  end

  def parse_tag_61
    match = super(%r{^:61:(?<value_date>\d{6})
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

  def parse_tag_86
    if @line.match(/^:86:(.*)$/)
      @line = $1.strip
      @sepa ? determine_description_after_sepa : determine_description_before_sepa
      @transaction.description = @description.strip
    end
  end

  def determine_description_before_sepa
    if @description.nil? 
      @description = @line
    else
      @description += ' ' + @line
    end
  end

  def determine_description_after_sepa
    hash = hashify_description(@line)
    @description = ''
    @description += hash['NAME'] if hash['NAME']
    @description += ' '
    @description += hash['REMI'] if hash['REMI']
  end

end