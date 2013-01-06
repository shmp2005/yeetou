# -*- coding: utf-8 -*-
class Other::Interest
  include Other::Abstract
  include Mongoid::Timestamps

  field :bank_id, type: String
  field :product_code, type: String
  field :published_at, type: Date
  field :rate, type: Float
  field :memo, type: String

  belongs_to :bank, :class_name => "Other::Bank"
  belongs_to :product_type, :class_name => "Other::ProductType", :foreign_key => :product_code

  index({product_code: 1}, {name: "product_code_index"})
  index({bank_id: 1}, {name: "bank_id_index"})
  index({published_at: 1}, {name: "published_at_index"})
  index({published_at: 1, rate: -1}, {name: "published_at_rate_index"})
  index({bank_id: 1, published_at: 1, product_code: 1}, {name: "bank_published_at_product_code_index"})

  scope :by_product_code, lambda { |p_code| where(:product_code => p_code).desc(:published_at) }
  scope :china_rate, lambda { where(:bank_id => '0') }
  scope :latest_china_rate, lambda { |p_code| china_rate.by_product_code(p_code).desc(:published_at) }
  scope :by_published_at, lambda { |published_at| lte(:published_at => published_at).desc(:published_at) }

  class << self

    def china_1y_fixed_rate
      memkey = "Other::Interest_china_1y_fix_rate"
      Rails.cache.fetch(memkey, :expires_in => 1.days) do
        f=Other::Interest.latest_china_rate("213").first
        f.rate.round(3) if f
      end
    end

    def china_current_rate
      memkey = "Other::Interest_china_current_rate"
      Rails.cache.fetch(memkey, :expires_in => 1.days) do
        f=Other::Interest.latest_china_rate("111").first
        f.rate.round(3) if f
      end
    end

    def query_rates(bank_id=0)
      max_published=Other::Interest.where(:bank_id => bank_id.to_s).max(:published_at)||Date.today
      Other::Interest.where(:published_at => max_published, :bank_id => bank_id.to_s).asc(:code)
    end

    def max_published_date_of_china_rate
      Other::Interest.where(:bank_id => "0").max(:published_at)
    end
  end
end
