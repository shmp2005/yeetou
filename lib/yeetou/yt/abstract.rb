# -*- coding: utf-8 -*-
module Yt
  module Abstract
    extend ActiveSupport::Concern

    included do
      include Mongoid::Document
      include Mongoid::Timestamps
      store_in session: "default"

    end

    module ClassMethods
      def log(message)
        puts "#{Time.now}==#{message}"
      end
    end
  end
end
