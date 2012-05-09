require 'rubygems'
require 'csv'
require 'json'
require 'nokogiri'

def convert_data_to_csv
  data_2007 = CSV.read("./2007_second_turn.csv", {:headers => true})
  data_2012 = CSV.read("./2012_second_turn.csv", {:headers => true})

  header = ["Bureau", "Nom Bureau", "variation exprimes", "variation PS", "variation UMP", "variation vote nul"]

  second_turn_data = []

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

end

def geoloc_from_kml(bureau)
  doc = Nokogiri::XML::Document.parse open("doc.kml")
  doc.remove_namespaces!

  # find and map bureau numbers and geoloc data for first coordinates of polygon representing the location of the bureau
  geodata = doc.css('Placemark').map do |c| 
    [
      c.css("SimpleData[name='ASSN']").first.content.split("-"), 
      c.css("coordinates").first.content.gsub(/,0\s.*/, "").split(",").reverse
    ]
  end

  # filter result on the parameter and pop the coordinates
  geodata = geodata.select{|c| c[0].include? bureau.gsub(/^0+/, "")}.pop[1]

  p "not found #{bureau}" if geodata.empty?

  return geodata
end

def convert_data_to_json
  data_2007 = CSV.read("./2007_second_turn.csv", {:headers => true})
  data_2012 = CSV.read("./2012_second_turn.csv", {:headers => true})

  second_turn_data_by_bureau = {}

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

    p "#{result_2007[1]}"
    if second_turn_data_by_bureau.has_key?(result_2007[1])
      p second_turn_data_by_bureau[result_2007[1]].inspect
      second_turn_data_by_bureau[result_2007[1]][2] += data_2012[index][5].to_i - result_2007[5].to_i
      second_turn_data_by_bureau[result_2007[1]][3] += data_2012[index][7].to_i - result_2007[7].to_i
      second_turn_data_by_bureau[result_2007[1]][4] += data_2012[index][9].to_i - result_2007[9].to_i
      second_turn_data_by_bureau[result_2007[1]][5] += data_2012[index][4].to_i - result_2007[4].to_i
    else
      lat, lng = geoloc_from_kml(result_2007[0])
      p lat
      second_turn_data_by_bureau[result_2007[1]] = [
        lat.to_f, lng.to_f,
        data_2012[index][5].to_i - result_2007[5].to_i,
        data_2012[index][7].to_i - result_2007[7].to_i,
        data_2012[index][9].to_i - result_2007[9].to_i,
        data_2012[index][4].to_i - result_2007[4].to_i
      ]
    end
    index += 1
  end

  second_turn_bureau_hash = []
  second_turn_data_by_bureau.each do |key, data|
    second_turn_bureau_hash << {
      "Bureau" => key,
      "geo" => {"lat" => data[0], "lng" => data[1]},
      "variations" => {
        "exprime" => data[2],
        "PS" => data[3],
        "UMP" => data[4],
        "nul" => data[5]
      }
    }
  end

  File.open("visu_analytics/data_second_turn_bureau.json","w") do |f|
    f.write(second_turn_bureau_hash.to_json)
  end
end

convert_data_to_json
