# -*- coding: utf-8 -*-
# 最新额收益和风险指标
class Fund::ProfitRisk

  include Fund::Abstract

  belongs_to :fund, :class_name => 'Fund::Fund', :foreign_key => 'symbol'

  field :o_id, type: Integer
  field :symbol, type: String
  field :name, type: String
  field :establish_date, type: Date
  
  # profits
  field :latest_day_profit, type: Float
  field :latest_week_profit, type: Float
  field :latest_month_profit, type: Float
  field :latest_quarter_profit, type: Float
  field :latest_year_profit, type: Float
  field :two_year_annualized_profit, type: Float
  field :three_year_annualized_profit, type: Float
  field :four_year_annualized_profit, type: Float
  field :five_year_annualized_profit, type: Float
  field :total_profit, type: Float
  field :this_week_profit, type: Float
  field :this_month_profit, type: Float
  field :this_quarter_profit, type: Float
  field :this_year_profit, type: Float
  field :two_year_profit, type: Float
  field :three_year_profit, type: Float

  # risks
  field :month_beta, type: Float
  field :quarter_beta, type: Float
  field :year_beta, type: Float
  field :day_max_declined, type: Float
  field :week_max_declined, type: Float
  field :month_max_declined, type: Float
  field :quarter_max_declined, type: Float
  field :year_max_declined, type: Float
  field :max_recovery_time, type: Integer
  field :month_sharp_ratio, type: Float
  field :quarter_sharp_ratio, type: Float
  field :year_sharp_ratio, type: Float
  field :month_sortino_ratio, type: Float
  field :quarter_sortino_ratio, type: Float
  field :year_sortino_ratio, type: Float
  field :day_rise_probability, type: Float
  field :week_rise_probability, type: Float
  field :month_rise_probability, type: Float
  field :quarter_rise_probability, type: Float

end
