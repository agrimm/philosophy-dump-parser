class Page
  attr_accessor :text

  def initialize(title, id, text)
    raise unless self.class.valid?(title, id, text)
    @title, @id, @text = title, id, text
  end

  def self.new_if_valid(title, id, text)
    if valid?(title, id, text)
      return new(title, id, text)
    else
      return nil
    end
  end

  def self.valid?(title, id, text)
    return false if title =~ /:/
    return false if id < 1
    return false if text.empty?
    return true
  end
end

