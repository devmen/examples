# encoding: utf-8

prawn_document do |pdf|
  pdf.font_families.update("fonts" => {
    :normal      => "#{Rails.root}/lib/prawn/fonts/verdana.ttf",
    :bold        => "#{Rails.root}/lib/prawn/fonts/verdanab.ttf",
    :italic      => "#{Rails.root}/lib/prawn/fonts/verdanait.ttf",
    :bold_italic => "#{Rails.root}/lib/prawn/fonts/verdanabit.ttf" })
  pdf.font("fonts")

  pdf.text "#{@office.name}", :size => 30, :style => :bold
  pdf.move_down 20

  address = @office.address
  pdf.text "#{Office.human_attribute_name(:country)} - #{address.country}"
  pdf.text "#{Office.human_attribute_name(:state)} - #{address.state}"
  pdf.text "#{Office.human_attribute_name(:city)} - #{address.city}"
  pdf.text "#{Office.human_attribute_name(:street)} - #{address.street}"
  pdf.text "#{Office.human_attribute_name(:house_number)} - #{address.house_number}"
  pdf.text "#{Office.human_attribute_name(:zipcode)} - #{address.zipcode}"

  pdf.image open("http://static-maps.yandex.ru/1.x/?pt=#{address.geocode_address.gml_lnglat}&l=map&size=250,250&z=15&key=#{YMaps.key}")
end
