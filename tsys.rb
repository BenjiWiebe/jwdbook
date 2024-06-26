#!/usr/bin/ruby
require 'sqlite3'

db = SQLite3::Database.open 'bank.db'
db.results_as_hash = true
deposits_filename = 'tsys_deposits.out.ahk'
sql_mark_entered = "update txes set entered = 1  where type='ACH DEPOSIT' and desc like 'TSYS%' and entered=0"
results = db.query "select date,amount from txes where type='ACH DEPOSIT' and desc like 'TSYS%' and entered=0"

print "This will overwrite #{deposits_filename} - press ENTER to continue:"
gets

txes_written = 0
f = File.open(deposits_filename, "w")
f.puts 'Esc::ExitApp'
f.puts 'WinWait "FarmBooks -"'
f.puts 'WinActivate "FarmBooks -"'

results.each do |row|

  ymd = row['date']
  year = ymd[0..3]
  month = ymd[4..5]
  day = ymd[6..7]

  amount=row['amount']

  f.puts <<-AHK
SendText '#{month}'
SendText '#{day}'
SendText '#{year}\`n'
SendText 'TSYS\`n'
Sleep 70
SendText '#{amount}\`n\`n\`n\`n\`n#{amount}\`n'
Sleep 50
Send '!c'
Sleep 250
AHK
  txes_written += 1
end
db.execute sql_mark_entered

puts "Wrote #{txes_written} to #{deposits_filename} and marked them as entered."
