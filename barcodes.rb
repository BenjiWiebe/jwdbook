#!/usr/bin/ruby
require 'barby'
require 'barby/barcode/code_128'
require 'barby/outputter/png_outputter'
require 'barby/outputter/html_outputter'
require 'pry'
require 'date'

class GFI_code
  attr_accessor :gtin14, :date_type, :weight, :batch
  GTIN_PREFIX = '01'
  PRODUCTION = '11'
  PACKAGING = '13'
  BEST_BEFORE = '15'
  EXPIRATION = '17'
  KILOGRAMS = '310'
  POUNDS = '320'

  def initialize
    # calculate 6 months from today
    d = Date.today >> 6
    # YYMMDD
    result = d.year.to_s[2..3]
    result += d.month.to_s
    result += d.day.to_s
    @date = result
    @date_type = BEST_BEFORE
  end

  # format_weight('22.50', POUNDS, textual: true)
  # the first argument is the weight as a string, with a . for the decimal
  # the second argument is POUNDS or kilograms
  # textual: true surrounds the prefix with parentheses for printing beneath the barcode
  # textual: false (default) does not.
  def format_weight(weight, type, textual: false)
    parts = weight.split('.')
    weight = weight.tr('.', '')
    deccount = '0'
    if parts.length > 1
      deccount = parts.last.size.to_s
    end
    if textual
      p1 = '('
      p2 = ')'
    else
      p1 = ''
      p2 = ''
    end
    padding = '0' * (6 - weight.length) #pad with leading zeroes, to 6 characters
    return p1 + type + deccount + p2 + padding + weight
  end

  def _data(textual: false)
    if textual
      p1 = '('
      p2 = ')'
    else
      p1 = p2 = ''
    end
    return p1 + '01' + p2 + @gtin14 + p1 + @date_type + p2 + @date + format_weight(@weight, POUNDS, textual: textual) + p1 + '10' + p2 + @batch
  end
  def data
    return _data(textual: false)
  end
  def text
    return _data(textual: true)
  end
end

g = GFI_code.new
g.gtin14 = '00850059295014'
g.weight = '22.50'
g.batch = '2315'


barcode = Barby::Code128.new(Barby::Code128::FNC1 + g.data)
out = Barby::PngOutputter.new(barcode)
File.open('barcode.png', 'wb'){|f| f.write out.to_png }
puts g.text
