require 'rubygems'
require 'csv'
require 'json'

data_2007 = CSV.read("./2007_second_turn.csv", {:headers => true})
data_2012 = CSV.read("./2012_second_turn.csv", {:headers => true})

header = ["Bureau", "Nom Bureau", "variation exprimes", "variation PS", "variation UMP", "variation vote nul"]

second_turn_data = []

index = 0
data_2007.each do |result_2007|

  # New bureaux in 2012
  if ["0022A", "0044B", "0198B", "0203B"].include? data_2012[index][0]
    index += 1
  end

  # go next if bureaux doesn't exist anymore in 2012
  if result_2007[0] != data_2012[index][0]
    p "#{result_2007[0]} != #{data_2012[index][0]}"
    next
  end

  second_turn_data << [result_2007[0], result_2007[1],
    data_2012[index][5].to_i - result_2007[5].to_i,
    data_2012[index][7].to_i - result_2007[7].to_i,
    data_2012[index][9].to_i - result_2007[9].to_i,
    data_2012[index][4].to_i - result_2007[4].to_i
  ]
  index += 1
end

CSV.open("./analytics_second_turn.csv", "wb") do |file| 
  file << header
  second_turn_data.each{|c| file << c}
end

second_turn_hash = []
second_turn_data.each do |data|
  second_turn_hash << {
    header[0] => data[0],
    header[1] => data[1],
    header[2] => data[2],
    header[3] => data[3],
    header[4] => data[4],
    header[5] => data[5],
  }
end

File.open("visu_analytics/data_second_turn.json","w") do |f|
  f.write(second_turn_hash.to_json)
end
