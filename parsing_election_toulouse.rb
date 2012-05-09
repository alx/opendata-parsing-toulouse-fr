require 'rubygems'
require 'nokogiri'
require 'csv'
require 'net/http'

def parse_page(bureau, data, csv_filename)
  doc = Nokogiri::HTML(data)
  result = [bureau]

  infos = doc.css('td[class="Infos"]')[6..11]
  bureau_name = infos[0].content
  bureau_data = infos[1..4].map{|c| c.content.to_i}
  taux_participation = infos[5].content.gsub(",",".").gsub("%","").to_f
  result.concat([bureau_name, bureau_data, taux_participation].flatten)

  doc.css('tbody tr[height="15"]').each do |row|
    candidate_data = row.css('td[align="right"]')
    p candidate_data.map{|c| c.content}
    voix = candidate_data[0].content.to_i
    taux = candidate_data[1].content.gsub(",",".").gsub("%","").to_f
    result.concat([voix, taux])
  end

  CSV.open("./#{csv_filename}", "ab") do |file|
    file << result
  end
end


def get_page(result, bureau)
  p "parse bureau #{bureau}"
  res = Net::HTTP.start('elections.toulouse.fr', 80) do |http|
    http.get("/resultats_2012/resultats_bureau.asp?bureau=#{bureau}&#{result[:params]}")
  end
  return res.body
end

def get_list_bureau(result)
  res = Net::HTTP.start('elections.toulouse.fr', 80) do |http|
    http.get("/resultats_2012/resultats_elect_pres.asp?#{result[:params]}")
  end
  doc = Nokogiri::HTML(res.body)
  return doc.css("option").map{|c| c.attribute("value").value}.sort{|a, b| a <=> b}
end

def parse_all
  [
    {:params => "scrutin=20070422%40%405%40%401%40%40Pr%E9sidentielles+2007%40%405%40%403", :csv => "2007_first_turn.csv"},
    {:params => "scrutin=20070506%40%406%40%402%40%40Pr%E9sidentielles+2007%40%405%40%403", :csv => "2007_second_turn.csv"},
    {:params => "scrutin=20120422%40%403%40%401%40%40Pr%E9sidentielles+2012%40%405%40%403", :csv => "2012_first_turn.csv"},
    {:params => "scrutin=20120506%40%404%40%402%40%40Pr%E9sidentielles+2012%40%405%40%402", :csv => "2012_second_turn.csv"}
  ].each do |result|
    get_list_bureau(result).reject{|bureau| bureau == "00000"}.each do |bureau|
      data = get_page(result, bureau)
      parse_page(bureau, data, result[:csv])
    end
  end
end

parse_all
