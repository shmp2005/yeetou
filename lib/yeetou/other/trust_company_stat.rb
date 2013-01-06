# -*- coding: utf-8 -*-
class Other::TrustCompanyStat
  include Other::Abstract
  include Mongoid::Timestamps

  YEAR=2011                                                 # 当前年度

  field :year, type: Integer, default: YEAR                 #统计年度
  field :company_name, type: String                         #信托公司名称
  field :avg_profit, type: Float                            #人均利润
  field :net_profit, type: Float                            #净利润
  field :net_profit_rank, type: Integer                     #净利润  排名
  field :total_income, type: Float                          #总收入
  field :total_income_rank, type: Integer                   #总收入  排名
  field :trust_income, type: Float                          #信托业务收入

  field :new_collection_capital, type: Float                #集合类新增资金
  field :new_single_capital, type: Float                    #单一类新增资金
  field :new_property_capital, type: Float                  #财产管理类新增资金
  field :new_sum_capital, type: Float                       #合计

  field :stock_capital, type: Float                         #存量资产
  field :stock_capital_rank, type: Float                    #存量资产  排名

  field :register_capital, type: Float                      #注册资本，单位 亿元
  field :register_capital_rank, type: Integer               #注册资本  排名
  field :net_capital, type: Float                           #净资本
  field :net_capital_rank, type: Integer                    #净资本  排名

  field :register_capital_unit, type: String, default: '亿元' #只有注册资本单位为亿元
  field :other_unit, type: String, default: '万元'            #其他单位，例如，利润，收入，资金，都是万元

  field :rating_capital, type: Integer                      #资本实力
  field :rating_business, type: Integer                     #业务能力
  field :rating_profit, type: Integer                       #盈利能力
  field :rating_management, type: Integer                   #信托管理能力
  field :rating_anti_risk, type: Integer                    #抗风险能力
  field :rating_overall, type: Integer                      #综合能力
  field :rating_overall_rank, type: Integer                 #综合能力  排名
  field :rating_rank_2010, type: Integer                    #2010年综合  排名
  field :rating_rank_delta, type: Integer                   #排名变化

  scope :by_name, lambda { |name| where(:company_name => name) }
  scope :by_year_and_name, lambda { |year, name| where(:year => year, :company_name => name) }

  class << self

  end
end
