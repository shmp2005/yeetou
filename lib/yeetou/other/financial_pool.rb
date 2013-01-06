# -*- coding: utf-8 -*-
class Other::FinancialPool
  include Other::Abstract
  include Mongoid::Timestamps

  PERIODS      =Hash['长期', '半年以上', '中期', '3~6月', '短期', '3个月内']
  FOREIGN_BANKS=%w[东亚银行 花旗银行 渣打银行 汇丰银行 德意志银行 星展银行 法兴银行 荷兰银行]

  field :financial_product_id, type: String
  field :name, type: String                           #冗余字段，产品名称
  field :bank_name, type: String                      #冗余字段，银行名称
  field :expected_profit, type: Float                 #预期收益率
  field :period, type: Integer                        #周期月份
  field :period_type, type: String                    #周期分类，长期，中期，短期
  field :period_desc, type: String                    #周期描述, 小于等于3月，3月到6月(含)，6月以上
  field :issue_end_date, type: Date                   # 结束日期
  field :confirmed_flag, type: Boolean, default: true #人工确认
  field :excluded_flag, type: Boolean, default: false #人工排除
  field :_id, type: String, default: -> { financial_product_id }

  index({period_type: 1}, {name: "period_type_index"})

  scope :rows, lambda { where(:confirmed_flag => true, :excluded_flag => false) }
  scope :by_name, lambda { |name| rows.where(:name => name) }
  scope :by_bank_name, lambda { |bank_name| rows.where(:bank_name => bank_name) }
  scope :by_period_type, lambda { |period| rows.where(:period_type => period) }
  scope :top_by_period_type, lambda { |period, top| by_period_type(period).gte(:issue_end_date => Date.today).desc(:expected_profit).desc(:created_at).limit(top) }

end


