module Yeetou
   module Yt
      class Order
	  def to_s
	    puts "hi, i am an Order"
	  end

	  class << self
	    def pay
	      puts "i want to pay you"
	    end
	  end
      end
  end	
end

class Yeetou::Yt::Product
    def to_s
       puts "yeetou product"
    end
end
