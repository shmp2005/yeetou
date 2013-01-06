module Fund
  class Book
    def publish
      puts "hi, i am a book"
    end

    class << self
      def read
        puts "i want to read you"
      end
    end
  end
end
