# -*- coding: utf-8 -*-
class Other::Saving
  include Other::Abstract
  include Mongoid::Timestamps

  field :bank_id, type: String
  field :name, type: String
  field :product_code, type: String
  field :min_deposit_amount, type: String
                                                # unit 月
  field :period, type: Integer
  field :rate, type: Float
  field :delta, type: Float
  field :delta_ratio, type: Float
  field :url, type: String
  field :state, type: Integer, default: 0
  field :buy_counter, type: Integer, default: 0 #购买数

  belongs_to :bank, :class_name => "Other::Bank"
  belongs_to :product_type, :class_name => "Other::ProductType", :foreign_key => :product_code

  index({bank_id: 1, product_code: 1}, {name: "bank_product_code_index"})

  scope :by_period, lambda { |p_min, p_max| gte(:period => p_min).lte(:period => p_max) }
  scope :by_bank, lambda { |bank_id| includes(:bank).includes(:product_type).where(:bank_id => bank_id).asc(:product_code) }
  scope :by_product_code, lambda { |p_code| includes(:bank).includes(:product_type).where(:product_code => p_code).desc(:rate) }
  scope :top10_buy_counter, lambda { desc(:buy_counter).limit(10) }
  scope :zczq, lambda { where(product_code: /^21/) }

  def cookie_key
    "#{self.class.name}_#{id}"
  end

  def tzp_url
    "/tz_search/deposit_info?t=#{id}"
  end

  def china_rate
    #memkey = "Other::Saving_China_Rate_#{self.product_code}"
    #Rails.cache.fetch(memkey, :expires_in => 1.days) do
    f=Other::Interest.latest_china_rate(product_code).first
    f.rate.round(3) if f
    #end
  end

  def features
    f = []
    f << 'high' if delta_ratio == 10
    f << 'low' if delta_ratio < 10
    if Other::Saving.cached_top10_by_buy_counter.include?(self.id)
      f << 'hot'
    end
    f << (self.bank.nation_wide? ? 'nation' : 'local')
    f
  end

  class << self

    def cached_top10_by_buy_counter
      memkey = "Other::Deposit.top10_by_buy_counter"
      Rails.cache.fetch(memkey, :expires_in => 1.day) do
        Other::Saving.top10_buy_counter.collect(&:id)
      end
    end
  end
end
