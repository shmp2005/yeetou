# -*- coding: utf-8 -*-
class Fund::Fund

  include Fund::Abstract

  UnvsScopes = {'全部'  => :all, '股票型' => :stock_type, '债券型' => :bond_type, '混合型' => :mixed_type,
                '指数型' => :exponent_type, '保本型' => :pg_type, 'QDII' => :qdii_type, 'ETF' => :etf_type, 'LOF' => :lof_type}

  belongs_to :company, :class_name => 'Fund::Company', :foreign_key => 'company_code'
  belongs_to :trustee, :class_name => 'Fund::Trustee', :foreign_key => 'trustee_code'

  has_one :extend_profile, :class_name => 'Fund::ExtendProfile', :foreign_key => 'symbol'
  has_one :profit_risk, :class_name => 'Fund::ProfitRisk', :foreign_key => 'symbol'
  has_one :profit_risk_class_rank, :class_name => 'Fund::ProfitRiskClassRank', :foreign_key => 'symbol'

  has_many :managers, :class_name => 'Fund::Manager', :foreign_key => 'symbol'
  has_many :net_values, :class_name => 'Fund::NetValue', :foreign_key => 'symbol'
  has_many :announces, :class_name => 'Fund::Announce', :foreign_key => 'symbol'
  has_many :day_profits, :class_name => 'Fund::DayProfit', :foreign_key => 'symbol'
  has_many :week_profits, :class_name => 'Fund::WeekProfit', :foreign_key => 'symbol'
  has_many :month_profits, :class_name => 'Fund::MonthProfit', :foreign_key => 'symbol'
  has_many :quarter_profits, :class_name => 'Fund::QuarterProfit', :foreign_key => 'symbol'
  has_many :half_year_profits, :class_name => 'Fund::HalfYearProfit', :foreign_key => 'symbol'
  has_many :year_profits, :class_name => 'Fund::YearProfit', :foreign_key => 'symbol'
  has_many :dividends, :class_name => 'Fund::Dividend', :foreign_key => 'symbol'
  has_many :fees, :class_name => 'Fund::Fee', :foreign_key => 'symbol'
  has_many :holders, :class_name => 'Fund::Holder', :foreign_key => 'symbol'
  has_many :industries, :class_name => 'Fund::Industry', :foreign_key => 'symbol'
  has_many :stocks, :class_name => 'Fund::Stock', :foreign_key => 'symbol'
  has_many :bonds, :class_name => 'Fund::Bond', :foreign_key => 'symbol'
  has_many :assets, :class_name => 'Fund::Asset', :foreign_key => 'symbol'
  has_many :year_profits, :class_name => 'Fund::YearProfit', :foreign_key => 'symbol'

  default_scope -> { desc(:latest_day_profit) }
  scope :open_type, where(open_flag: true, currency_flag: false)         # 开放式基金
  scope :currency_funds, where(currency_flag: true)                      # 货币型基金
  scope :close_type, where(open_flag: false)                             # 封闭式基金
  scope :stock_type, where(fund_style: '偏股型基金')                          # 股票型
  scope :bond_type, any_of({fund_style: '偏债型基金'}, {fund_style: '债券型基金'}) # 债券型
  scope :mixed_type, where(fund_style: '股债平衡型基金')                        # 混合型
  scope :exponent_type, where(invest_style: '指数型')                       # 指数型
  scope :pg_type, where(fund_style: '保本增值')                              # 保本型
  scope :qdii_type, where(fund_style: 'QDII')                            # QDII
  scope :etf_type, where(fund_kind: 'ETF')                               # ETF
  scope :lof_type, where(fund_kind: 'LOF')                               # LOF
  scope :can_buy, not_in(buy_state: [nil, '', '封闭期'])
  scope :can_redeem, not_in(redeem_state: [nil, '', '封闭期'])
  scope :can_buy_and_redeem, can_buy.can_redeem

  index({symbol: 1}, {unique: true, name: "symbol_index"})
  index({name: 1}, {unique: true, name: "name_index"})
  index({spell: 1}, {unique: false, name: "spell_index"})
  index({latest_day_profit: 1}, {unique: false, name: "latest_day_profit_index"})
  index({discount_rate: 1}, {unique: false, name: "discount_rate_index"})
  index({unv_per_ten_thousand: 1}, {unique: false, name: "unv_per_ten_thousand_index"})
  index({close_price: 1}, {unique: false, name: "close_price_index"})

  field :o_id, type: Integer                                             # 开放式基金唯一ID
  field :c_id, type: Integer                                             # 封闭式基金唯一ID
  field :symbol, type: String
  field :_id, type: String, default: -> { symbol }
  field :name, type: String
  field :full_name, type: String
  field :spell, type: String
  field :company_code, type: String
  field :trustee_code, type: String
  field :open_flag, type: Boolean, default: -> { 1 }
  field :currency_flag, type: Boolean                                    # 是否是货币型基金
  field :fund_type, type: String
  field :establish_date, type: Date
  field :initial_amount, type: Float
  field :fund_kind, type: String
  field :fund_style, type: String
  field :invest_style, type: String
  field :index_symbol, type: String                              # 指数基金标的指数代码
  field :redemption, type: String
  field :fund_key, type: String
  field :buy_state, type: String
  field :redeem_state, type: String
  field :latest_day_profit, type: Float                                  # 日增长率
  field :latest_week_profit, type: Float                                 # 周增长率
  field :unv_per_ten_thousand, type: Float                               #万份单位收益
  field :discount_rate, type: Float                                      #（折价率）
                                                                         # 以下是封闭式基金专用属性
  field :close_price, type: Float                                        # 收盘价
  field :unit_amount, type: Float                                        # 基金单位总额
  field :renew_start_date, type: Date                                    # 存续起始日
  field :renew_end_date, type: Date                                      # 存续终止日
  field :appear_date, type: Date                                         # 上市日期
  field :renew_due, type: Float                                          # 存续期限
  field :market_code, type: String                                       # 市场代码

  def self.features
    %w[cx_rate stable low_risk]
  end

  def tzp_url
    "/funds/#{symbol}"
  end

  #根据带入的日期，返回当前基金净值
  def get_net_value(publish_date=nil)

    if publish_date.nil?
      if self.currency_flag
        nv = Fund::CurrencyNetValue.where(symbol: self.symbol).desc(:report_date).first
      else
        nv = Fund::NetValue.where(symbol: self.symbol).desc(:publish_date).first
      end
      return {} if nv.nil?
      publish_date = nv.publish_date.ymd
    else
      publish_date = publish_date.to_s(:db) unless publish_date.is_a?(String)
    end

    memkey = "Fund::Fund_get_net_value_#{self.symbol}_#{publish_date}_7"

    #Rails.cache.delete memkey

    result = Rails.cache.read(memkey)
    return result if result
    if self.currency_flag
      nv = Fund::CurrencyNetValue.where(symbol: self.symbol).lte(report_date: publish_date).desc(:report_date).first
      nv = {:unv_per_ten_thousand        => nv.unv_per_ten_thousand,
            :seven_day_annualized_profit => nv.seven_day_annualized_profit,
            :unv_date                    => publish_date} if nv
    else
      nv = Fund::NetValue.where(symbol: self.symbol).lte(publish_date: publish_date).desc(:publish_date).first
      nv = {:unv => nv.unv, :total_unv => nv.total_unv, :unv_date => publish_date} if nv
    end
    # 如果有值，缓存3天，否则缓存15分钟。
    expires_in = (nv && 3.days || 15.minutes)
    Rails.cache.write(memkey, nv || {}, :expires_in => expires_in)
    nv || {}
  end
end
