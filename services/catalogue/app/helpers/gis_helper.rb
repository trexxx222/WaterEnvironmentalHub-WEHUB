module GisHelper
  
  def latitude_longitude_from_bbox(bounding_box)
    if bounding_box.is_a? Hash
      bounding_box =  "#{bounding_box[:west]} #{bounding_box[:south]}, #{bounding_box[:east]} #{bounding_box[:north]}"
    end
    latitude = ''
    longitude = ''
    centroid = "centroid('MULTIPOINT(#{bounding_box})')"
    result = execute("SELECT x(#{centroid}), y(#{centroid})")[0]
    if result
      latitude = result.select{ |column| column =~ /^y$/i }.first[1]
      longitude = result.select{ |column| column =~ /^x$/i }.first[1]
    end
    
    "#{latitude},#{longitude}"
  end  
  
  def coordinates_to_params_from_bounding_box(params)
    if params[:bounding_box]
      params.merge!(:coordinates => latitude_longitude_from_bbox(params[:bounding_box]))
    end
    params
  end
  
end
