class App
  attr_reader :name
  attr_accessor :title, :creator, :version, :update_date, :size, :description, :whats_new, :url

  def initialize(name)
    @name = name
  end

end
