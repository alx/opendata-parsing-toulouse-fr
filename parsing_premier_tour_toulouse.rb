require 'rubygems'
require 'nokogiri'
require 'csv'
require 'net/http'

def parse_page(bureau, data)
  doc = Nokogiri::HTML(data)
  result = [bureau]
  result.concat(doc.css('td[class="Infos"]')[6..11].map{|c| c.content})
  doc.css('tbody tr[height="15"]').each do |row|
    result.concat(row.css('td[align="center"]').map{|c| c.content.to_i})
  end
  CSV.open("./first_turn.csv", "ab") do |file|
    file << result
  end
end


def get_page(bureau)
  p "parse bureau #{bureau}"
  res = Net::HTTP.start('elections.toulouse.fr', 80) do |http|
    http.get("/resultats_2012/resultats_bureau.asp?bureau=#{bureau}&scrutin=20120422%40%403%40%401%40%40Pr%E9sidentielles+2012%40%405%40%403")
  end
  return res.body
end

def get_list_bureau
  res = Net::HTTP.start('elections.toulouse.fr', 80) do |http|
    http.get("/resultats_2012/resultats_elect_pres.asp?scrutin=20120422%40%403%40%401%40%40Pr%E9sidentielles+2012%40%405%40%403")
  end
  doc = Nokogiri::HTML(res.body)
  return doc.css("option").map{|c| c.attribute("value")}
end

get_list_bureau.reject{|bureau| bureau == "00000"}.each do |bureau|
  data = get_page(bureau)
  parse_page(bureau, data)
end

