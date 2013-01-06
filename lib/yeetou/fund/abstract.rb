# -*- coding: utf-8 -*-
module Fund
  module Abstract
    extend ActiveSupport::Concern

    included do
      include Mongoid::Document
      store_in session: "fund"
    end

    module ClassMethods
      def log(message)
        puts "#{Time.now}==#{message}"
      end
    end
  end
end
