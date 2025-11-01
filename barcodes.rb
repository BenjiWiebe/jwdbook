#!/usr/bin/ruby
require 'barby'
require 'barby/barcode/code_128'
require 'barby/outputter/png_outputter'
require 'barby/outputter/html_outputter'
require 'pry'
require 'date'
require 'erb'

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
  end

  def set_date(date_type, date=nil)
    @date_type = date_type
    if date_type == BEST_BEFORE
      # calculate 6 months from today
      d = Date.today >> 6
    else
      d = date
    end
    # YYMMDD format
    yy = d.year.to_s[2..3]
    mm = d.month.to_s
    dd = d.day.to_s
    mm.prepend('0') if mm.length == 1
    dd.prepend('0') if dd.length == 1
    @date = yy + mm + dd
  end

  # format_weight('22.50', POUNDS, textual: true)
  # the first argument is the weight as a string, with a . for the decimal
  # the second argument is POUNDS or kilograms
  # textual: true surrounds the prefix with parentheses for printing beneath the barcode
  # textual: false (default) does not.
  def format_weight(weight, type, textual: false)
    weight = weight.to_s
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
    return p1 + '01' + p2 + @gtin14 + p1 + @date_type + p2 + @date + format_weight(@weight, POUNDS, textual: textual) + p1 + '10' + p2 + @batch.to_s
  end
  def data
    return _data(textual: false)
  end
  def text
    return _data(textual: true)
  end
end

GTINS = {
  CRR40LB: {
    gtin14: "90850059295451",
    title: "COTTONWOOD RIVER RESERVE",
    subtitle: "1 x approx. 40LB block"
  },
  CRR2X5LB: {
    gtin14: "90850059295000",
    title: "COTTONWOOD RIVER RESERVE",
    subtitle: "2 x approx. 5LB blocks"
  }
}

batch_weights={ 2126 => ["2024-08-15", 10,10.1,10.2,10.3], 2143 => ["2021-01-01", 9.99,9.98,9.97]}
product = :CRR40LB


label_contents=[]
label_index = 0
batch_weights.each_pair do |batch,weights|
  batch_date = Date.parse(weights.shift)
  weights.each do |weight|
    g = GFI_code.new
    g.set_date(GFI_code::PRODUCTION, batch_date)
    g.gtin14 = GTINS[product][:gtin14]
    g.weight = weight
    g.batch = batch

    barcode_image_file = "barcode_images/barcode#{label_index}.png"

    barcode = Barby::Code128.new(Barby::Code128::FNC1 + g.data)
    out = Barby::PngOutputter.new(barcode)
    out.xdim=2
    out.ydim=out.xdim
    out.height=20
    out.margin=0
    File.open(barcode_image_file, 'wb'){|f| f.write out.to_png }
    puts "Generated #{barcode_image_file}: #{g.text}"

    make_date = batch_date.strftime('%b %e, %Y')
    padded_weight = format('%.2f', weight.to_f)
    title = GTINS[product][:title]
    subtitle = GTINS[product][:subtitle]

    label_template = ERB.new File.read('label_template.erb.html')
    label_contents << label_template.result(binding)
    label_index += 1
  end
end


f=File.open('template.html')
outfile=File.open('printable.html','w')
f.each_line do |line|
  if /^[[:space:]]*@label(\d+)@[[:space:]]*$/ =~ line
    outfile.write label_contents[$1.to_i]
  else
    outfile.write line
  end
end
f.close
