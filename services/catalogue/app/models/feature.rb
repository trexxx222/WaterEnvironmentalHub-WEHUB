class Feature 
  include ActiveModel::Validations
  include ActiveModel::Conversion  
  extend ActiveModel::Naming
  
  attr_accessor :uuid, :feature_type, :name
  
  def initialize(uuid, feature_type, name='')
    @feature_type = feature_type
    @uuid = uuid
    @name = name
  end
  
  def persisted?
    false
  end
  
  class << self
    def all
      return []
    end
  end
  
  def data
    tablename = self.find_by_uuid(uuid)
    if tablename != nil          
      dataset_name = tablename.gsub("_#{uuid}", '')
      
      { :tablename => dataset_name, :data => execute("SELECT * FROM #{tablename}") }
    end
  end
  
  def keywords
    if is_base_data
      observation_data = GeoServerTranslator.new.feature_fields(uuid)
      keywords = extract_keywords(observation_data)
    else
      observation_data = data_lightweight
      if observation_data[:data].count > 0
        keywords = extract_keywords(observation_data[:data][0])
      end
    end   
    
    if !keywords.nil?
      keywords = clean_id_fields(keywords)
      
      keywords.uniq + synonyms.uniq
    end
    
    keywords
  end
  
  def name
    @name
  end
  
  def filename(extension='')
    filename = "#{name.gsub(' ','_')}_#{uuid.gsub('-','_')}".downcase
    if !extension.empty?
      filename = "#{filename}.#{extension}" 
    end
    filename
  end
  
  def tablename
    if is_base_data
      raise ArgumentError, "Features of type base data don't have tables"
    else
      resolve_tablename
    end
  end
    
  def is_base_data
    feature_type.name.downcase.index('base') != nil
  end
  
  def to_s
    puts "Feature:\n\t#{uuid}\n\t#{name}\n\t#{feature_type.to_s}"
  end

  private 
  
  def resolve_tablename
    tablename = nil
    if uuid.match(/[\w]{8}-[\w]{4}-[\w]{4}-[\w]{4}-[\w]{12}/) != nil
      uuid_with_underscores = uuid.gsub(/-/, '_')      
      begin
        tablename = execute("SELECT tablename FROM pg_tables WHERE tablename LIKE '%#{uuid_with_underscores}%'")[0]['tablename']
      rescue
        raise ArgumentError, "Observation data for #{uuid} could not be found"  
      end
    else
      raise ArgumentError, "Expected a valid uuid, but got #{uuid}"
    end
    tablename
  end

  def data_lightweight
    tablename = resolve_tablename
    if tablename != nil          
      dataset_name = tablename.gsub("_#{uuid}", '')
      
      { :tablename => dataset_name, :data => execute("SELECT * FROM #{tablename} LIMIT 1") }
    end
  end
      
  def extract_keywords(observation_data)
    keywords = []
    
    observation_data.each do |k, v|
      if /\(/ =~ k
        if /(?<title_with_out_units>[\D]*)\(/ =~ k
          keywords.push(title_with_out_units.strip)
        end
        if /\((?<measurement_unit>.+)\)/ =~ k
          keywords.push(measurement_unit)
        end
      else
        keywords.push(k)
      end
    end

    keywords
  end
      
  def synonyms
    synonyms = []
  end
    
  def clean_id_fields(keywords)
    ['id','gid','nid'].each do |item|
      keywords.delete(item)
    end
    keywords.delete_if { |keyword| keyword.index('_id') }
    keywords.each_with_index do |keyword, index|
       keywords[index] = keyword.gsub('_',' ')
     end
    keywords
  end
  
  def execute(sql)
    ActiveRecord::Base.connection.execute(sql)
  end

end