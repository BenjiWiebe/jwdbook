#!/usr/bin/ruby
require 'sqlite3'

db = SQLite3::Database.open 'bank.db'
db.results_as_hash = true
db.execute "create table if not exists raw_txes (date text,refno text,amount int,type text,desc text)"

# entered column: 0 - not entered. 1 - entered into farmbooks.
db.execute "create table if not exists txes (date text,refno text,amount int,type text,desc text,entered int)"

results = db.query "select date,refno,amount,type,desc from raw_txes"

stmt = db.prepare("insert into txes (date,refno,amount,type,desc,entered) values (?,?,?,?,?,?)")
converted = 0
db.transaction

results.each do|row|
  month, day, year = row['date'].split('/')
  month.prepend('0') if month.length == 1
  day.prepend('0') if day.length == 1
  date="#{year}#{month}#{day}"
  stmt.execute(date,row['refno'],row['amount'],row['type'],row['desc'],0)
  converted += 1
end
db.execute("delete from raw_txes")
db.commit

puts "Converted #{converted} records"
