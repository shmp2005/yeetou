# -*- coding: utf-8 -*-
class Fund::ExpProfit

  include Fund::Abstract

  field :symbol, type: String
  #profit_type [month, quarter, year]
  field :profit_type, type: String
  field :year, type: Integer
  # month: (1..12), quarter: (1..4), year: [year]
  field :number, type: Integer
  field :profit, type: Float

  scope :year_on, lambda { |year| where(year: year) }
  scope :years, lambda { where(profit_type: 'year') }
  scope :quarters, lambda { where(profit_type: 'quarter') }
  scope :months, lambda { where(profit_type: 'month') }

  index({symbol: 1}, {name: "symbol_index"})
  index({symbol: 1, profit_type: 1, year: 1, number: 1}, {unique: false, name: "symbol_profit_year_number_index"})

  class << self


  end
end
