# -*- coding: utf-8 -*-
# 开基净值
class Fund::NetValue

  include Fund::Abstract

  belongs_to :fund, :class_name => 'Fund::Fund', :foreign_key => 'symbol'

  field :o_id, type: Integer
  field :symbol, type: String
  field :publish_date, type: Date
  field :currency, type: String
  field :unv, type: Float
  field :total_unv, type: Float

  index({symbol: 1, publish_date: 1}, {unique: true, name: "symbol_publish_date_index"})

  class << self

    # 从多只基金中取最早有净值数据的日期(取最早有数据那支基金的日期)
    def get_earliest_date_by_symbols(symbols)
      symbols = symbols.split(',') unless symbols.is_a?(Array)
      nv = Fund::NetValue.where(:symbol.in => symbols).asc(:publish_date).first
      nv && nv.publish_date || Date.today
    end

    # 从多只基金中取最早有净值数据的日期(取最近有数据那支基金的日期)
    def get_latest_earliest_date_by_symbols(symbols)
      latest = '1980-1-1'.to_date
      symbols = symbols.split(',') unless symbols.is_a?(Array)
      symbols.each do |symbol|
        nv = Fund::NetValue.where(symbol: symbol).asc(:publish_date).first
        latest = nv.publish_date if nv && nv.publish_date > latest
      end
      latest
    end

    # 获取最近的开放式基金数据日期
    def get_latest_date
      return @get_latest_date if @get_latest_date
      memkey           = "Fund::NetValue_get_latest_date_6"
      @get_latest_date = Rails.cache.fetch(memkey, :expires_in => 30.minutes) do
        date1 = Fund::Legacy::Nav.order('PublishDate asc').last.PublishDate.to_date.to_s(:db)
        date2 = Fund::Legacy::Nav.where(['PublishDate <> ?', date1]).order('PublishDate asc').last.PublishDate.to_date.to_s(:db)
        [date1, date2]
      end
    end
  end
end
