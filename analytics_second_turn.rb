require 'rubygems'
require 'csv'

data_2007 = CSV.read("./2007_second_turn.csv", {:headers => true})
data_2012 = CSV.read("./2012_second_turn.csv", {:headers => true})

analytics_second_turn = []
analytics_second_turn << ["Bureau", "Nom Bureau", "variation exprimes", "variation PS", "variation UMP", "variation vote nul"]

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

  analytics_second_turn << [result_2007[0], result_2007[1],
    data_2012[index][5].to_i - result_2007[5].to_i,
    data_2012[index][7].to_i - result_2007[7].to_i,
    data_2012[index][9].to_i - result_2007[9].to_i,
    data_2012[index][4].to_i - result_2007[4].to_i
  ]
  index += 1
end

CSV.open("./analytics_second_turn.csv", "wb") do |file| 
  analytics_second_turn.each{|c| file << c}
end
