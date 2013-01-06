# -*- coding: utf-8 -*-
class Other::LccpBacklog
  include Other::Abstract
  include Mongoid::Timestamps

  field :lccp_id, type: String

  #0, 确认，10，新数据，未确认和排除，99，已排除
  field :state, type: Integer

  belongs_to :financial_product, :class_name => 'Other::FinancialProduct', :foreign_key => :lccp_id

  index({ lccp_id: 1 }, { name: "lccp_id_index", unique: true })

  STATES = Hash[0, '已确认', 10, '新数据', 99, '已排除']

  scope :confirmed, lambda { where(state: 0) }
  scope :pending, lambda { where(state: 10) }
  scope :excluded, lambda { where(state: 99) }

  def confirmed?
    state == 0
  end

  def excluded?
    state == 99
  end

  def pending?
    state == 10
  end

  def exclude
    update_attributes state: 99
  end

  def confirm
    update_attributes state: 0
    Other::LccpPool.add_new(lccp_id, "来源于备选池")
  end

  class << self

    def import

      log("移除过期理财产品")
      #移除过期理财产品
      out_ids = Other::FinancialProduct.pre_on_sales.collect(&:id)
      Other::LccpPool.nin(lccp_id: out_ids).delete_all

      lccps = Other::FinancialProduct.pre_on_sales.gt0_expected_profit

      log("=========Import yeetou lccps #{lccps.count}========")
      lccps.each do |t|
        lccp = self.where(:lccp_id => t.id).first
        if lccp.nil?
          self.create! lccp_id: t.id, state: 10

          log("#{t.name} added")
        end
      end
      log("=============Done!===========")
    end
  end
end


