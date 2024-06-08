#!/usr/bin/ruby
require 'sqlite3'

db = SQLite3::Database.open 'bank.db'
db.results_as_hash = true
output_filename = 'loanacct_withdrawals.out.ahk'
sql_mark_entered = "update txes set entered = 1  where desc like 'TRANSFERRED TO LOAN ACCT %' and entered = 0"
results = db.query "select date,amount from txes where desc like 'TRANSFERRED TO LOAN ACCT %' and entered = 0"

print "This will overwrite #{output_filename} - press ENTER to continue:"
gets

txes_written = 0
f = File.open(output_filename, "w")
f.puts 'Esc::ExitApp'
f.puts 'WinWait "FarmBooks -"'
f.puts 'WinActivate "FarmBooks -"'

first_n_delayed = 3
delayed_by_ms = 4000
recvd_from = 'VINTAGE BANK'
atigd = '2021'
ent = '2200'
ext = '000'
type = :withdrawal #as opposed to :deposit

results.each do |row|

  ymd = row['date']
  year = ymd[0..3]
  month = ymd[4..5]
  day = ymd[6..7]

  amount=row['amount']
  skip_check_address = ''
  if type == :withdrawal
    skip_check_address = '`n' #we need an extra ENTER after the first amount to skip entering an address for the "check"
    if amount < 0 
      amount = amount.abs #get the amount without the '-'
    else
      puts "WARNING - withdrawal is not a negative amount!"
    end
  elsif type == :deposit
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
SendText '#{recvd_from}\`n'
Sleep 70
SendText '#{amount}\`n#{skip_check_address}#{atigd}\`n#{ent}\`n#{ext}\`n\`b\`n#{amount}\`n'
Sleep #{precommit_delay}
Send '!c'
Sleep 250
AHK
  txes_written += 1
end
db.execute sql_mark_entered

puts "Wrote #{txes_written} to #{output_filename} and marked them as entered."
