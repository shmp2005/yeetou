# -*- coding: utf-8 -*-
# 最新额收益和风险指标 排名
class Fund::ProfitRiskClassRank

  include Fund::Abstract

  belongs_to :fund, :class_name => 'Fund::Fund', :foreign_key => 'symbol'

  field :o_id, type: Integer
  field :symbol, type: String

  # profits Class Rank
  field :latest_day_profit_class_rank, type: String
  field :latest_week_profit_class_rank, type: String
  field :latest_month_profit_class_rank, type: String
  field :latest_quarter_profit_class_rank, type: String
  field :latest_year_profit_class_rank, type: String
  field :two_year_annualized_profit_class_rank, type: String
  field :three_year_annualized_profit_class_rank, type: String
  field :four_year_annualized_profit_class_rank, type: String
  field :five_year_annualized_profit_class_rank, type: String
  field :total_profit_class_rank, type: String
  field :this_week_profit_class_rank, type: String
  field :this_month_profit_class_rank, type: String
  field :this_quarter_profit_class_rank, type: String
  field :this_year_profit_class_rank, type: String
  field :two_year_profit_class_rank, type: String
  field :three_year_profit_class_rank, type: String

  # risks Class Rank
  field :month_beta_class_rank, type: String
  field :quarter_beta_class_rank, type: String
  field :year_beta_class_rank, type: String
  field :day_max_declined_class_rank, type: String
  field :week_max_declined_class_rank, type: String
  field :month_max_declined_class_rank, type: String
  field :quarter_max_declined_class_rank, type: String
  field :year_max_declined_class_rank, type: String
  field :max_recovery_time_class_rank, type: String
  field :month_sharp_ratio_class_rank, type: String
  field :quarter_sharp_ratio_class_rank, type: String
  field :year_sharp_ratio_class_rank, type: String
  field :month_sortino_ratio_class_rank, type: String
  field :quarter_sortino_ratio_class_rank, type: String
  field :year_sortino_ratio_class_rank, type: String
  field :day_rise_probability_class_rank, type: String
  field :week_rise_probability_class_rank, type: String
  field :month_rise_probability_class_rank, type: String
  field :quarter_rise_probability_class_rank, type: String

  def percent_by(field)
    field = field.to_s + "_class_rank" unless field.to_s =~ /_class_rank$/

    f = self.send field.to_sym
    if f.present?
      ranks = f.split("/")
      (ranks.first.to_f*100/ranks.last.to_f).round(2)
    else
      100 #a huge number
    end
  end

end
