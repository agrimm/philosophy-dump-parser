class Page
  attr_accessor :text

  def initialize(title, text)
    raise unless self.class.valid?(title, text)
    @title, @text = title, text
  end

  def self.new_if_valid(title, text)
    if valid?(title, text)
      return new(title, text)
    else
      return nil
    end
  end

  def self.valid?(title, text)
    return false if title =~ /:/
    return false if text.empty?
    return true
  end
end

