# -*- coding: utf-8 -*-
class Other::FinancialBank
  include Other::Abstract
  include Mongoid::Timestamps

  field :name, type: String #银行名称
  field :latest_year_avg_ep, type: Float #过去一年平均预期收益率
  field :latest_year_avg_ap, type: Float #过去一年平均实际收益率
  field :latest_year_target_rate, type: Float #过去一年预期收益达标率
  field :issue_volume, type: Integer #过去一年发行量
  field :last_roll_date, type: DateTime #最后更新日期

  index({name: 1}, {name: "name_index"})

  scope :by_name, lambda { |name| where(:name => name) }
  scope :issue_volumes, lambda { banks.gt(:issue_volume => 0) }
  scope :banks, lambda { ne(:name => '市场平均') }

  class << self

  end
end


