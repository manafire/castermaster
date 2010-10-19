class Sponsor < ActiveRecord::Base
  
  def position
    if force_top?
      rand
    else
      rand + 1
    end
  end
  
  class << self
    def active
      where(['active = ?', true])
    end
  end
end
