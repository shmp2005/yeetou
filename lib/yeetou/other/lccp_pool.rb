# -*- coding: utf-8 -*-
class Other::LccpPool
  include Other::Abstract
  include Mongoid::Timestamps

  field :lccp_id, type: String
  field :memo, type: String

  belongs_to :financial_product, :class_name => 'Other::FinancialProduct', :foreign_key => :lccp_id

  index({ lccp_id: 1 }, { name: "lccp_id_index", unique: true })

  def to_backlog
    backlog = Other::LccpBacklog.where(lccp_id: lccp_id).first
    backlog.update_attributes state: 10 if backlog

    self.delete
  end

  class << self

    def add_new(lccp_id, memo=nil)
      lccp = self.where(:lccp_id => lccp_id).first
      if lccp.nil?
        self.create! lccp_id: lccp_id, memo: memo

        log("#{lccp_id} added with memo #{memo}")
      end
    end

    def daily_update

      log("移除过期理财产品")
      out_ids = Other::FinancialProduct.pre_on_sales.collect(&:id)
      Other::LccpPool.nin(lccp_id: out_ids).delete_all
      log("=============Done!===========")
    end
  end
end


