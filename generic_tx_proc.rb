#!/usr/bin/ruby
require 'sqlite3'

require_relative 'jobs.rb'

db = SQLite3::Database.open 'bank.db'
db.results_as_hash = true
output_filename = 'batch.out.ahk'
first_n_delayed = 3
delayed_by_ms = 4000

print "This will overwrite #{output_filename} - press ENTER to continue:"
gets

txes_written = 0
f = File.open(output_filename, "w")
f.puts <<-AHK
Result := MsgBox("Do you want to auto-enter transactions into FarmBooks?","Auto-enter?", "YesNo Icon! Default2")
if not (Result = "Yes")
  ExitApp
AHK
f.puts 'Esc::ExitApp'
f.puts 'WinWait "FarmBooks -"'
f.puts 'WinActivate "FarmBooks -"'

job = JOBS[0]
sql_mark_entered = "update txes set entered = 1 where entered = 0 and #{job[:where]}"
sql_select = "select date,amount from txes where entered = 0 and #{job[:where]}"

results = db.query sql_select
results.each do |row|

  ymd = row['date']
  year = ymd[0..3]
  month = ymd[4..5]
  day = ymd[6..7]

  amount=row['amount']
  skip_check_address = ''
  if job[:type] == :withdrawal
    skip_check_address = '`n' #we need an extra ENTER after the first amount to skip entering an address for the "check"
    if amount < 0 
      amount = amount.abs #get the amount without the '-'
    else
      puts "WARNING - withdrawal is not a negative amount!"
    end
  elsif job[:type] == :deposit
    if amount < 0
      puts "WARNING - deposit is a negative amount!"
    end
  end

  precommit_delay = 50

  if first_n_delayed > 0
    first_n_delayed -= 1
    precommit_delay = delayed_by_ms
  end

  # the `b`n after ext is to reload the correct description in after changing the ext on a potentially-memorized line. (farmbooks bug)
  f.puts <<-AHK
SendText '#{month}'
SendText '#{day}'
SendText '#{year}\`n'
SendText '#{job[:account]}\`n'
Sleep 70
SendText '#{amount}\`n#{skip_check_address}#{job[:atigd]}\`n#{job[:ent]}\`n#{job[:ext]}\`n\`b\`n#{amount}\`n'
Sleep #{precommit_delay}
Send '!c'
Sleep 250
AHK
  txes_written += 1
end

db.execute sql_mark_entered unless job[:do_not_record]

print "Wrote #{txes_written} to #{output_filename} and "
puts job[:do_not_record] ? "did not mark them as entered." : "marked them as entered."
