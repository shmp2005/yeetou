# -*- coding: utf-8 -*-
# 中国交易指数
class Fund::Exponent

  include Fund::Abstract

  field :trade_date, type: Date        #（交易日期）
  field :exchange, type: String        #（市场代码）
  field :symbol, type: String          #（指数代码）
  field :name, type: String            #（指数名称）
  field :last_close_price, type: Float #（前日收盘）
  field :close_price, type: Float      #（收盘）

  index({ symbol: 1, trade_date: 1 }, { name: "symbol_trade_date_index" })
  scope :trade_date_between, lambda { |date_range| between(trade_date: date_range) }
  scope :year_on, lambda { |year, symbol="000001"| where(:symbol => symbol).between(trade_date: ("#{year}-01-01".to_date.."#{year}-12-31".to_date)) }

  #
  # 000001  上证指数
  # 000300  沪深300   
  # H11025	货币基金
  # 399305	基金指数(深圳)
  # H11022	混合基金
  # H11024	ETF基金
  # 395011	封闭基金
  # H11021	股票基金
  # H11026	QDII基金
  # 000011	基金指数（上海）
  # H11023	债券基金
  #
  INDEX_SYMBOLS = %w[000001 000011 000300 399305 H11023 H11025
                     H11022 H11024 395011 H11021 H11026]

  default_scope -> { asc(:trade_date) }

  class << self

  end
end
