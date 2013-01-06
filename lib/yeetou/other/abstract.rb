# -*- coding: utf-8 -*-
module Other
  module Abstract
    extend ActiveSupport::Concern

    included do
      include Mongoid::Document
      store_in session: "other"

      def set_object_url
        if self.new_record?
          self.url = "manually added at #{Time.now.to_i}" unless self.url.present?
        end
      end
    end

    module ClassMethods
      def log(message)
        puts "#{Time.now}==#{message}"
      end

      def agent
        @agent ||= Mechanize.new
      end

      def get_doc(url)
        log(url)
        agent.get(url).parser
      end

      def to_date(str)
        str = c_str(str)
        if str.present?
          str.gsub(/年|月/, '-').gsub('日', '').to_date
        end
      end

      def c_str(str)
        (str||'').gsub(/--/, '').strip
      end

      def to_number(str)
        c_str(str).gsub(/[^\d.]/, '')
      end

      def to_boolean(str, cn_true_label='是', cn_false_label='否')
        str = c_str(str)
        if str.present?
          case str
            when cn_true_label then
              true
            when cn_false_label then
              false
            else
              nil
          end
        end
      end
    end
  end
end
