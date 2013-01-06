# -*- coding: utf-8 -*-
# 货币基金净值
class Fund::CurrencyNetValue

  include Fund::Abstract

  belongs_to :fund, :class_name => 'Fund::Fund', :foreign_key => 'symbol'

  field :o_id, type: Integer
  field :symbol, type: String
  field :report_date, type: Date
  field :unv_per_ten_thousand, type: Float        #万份单位收益
  field :seven_day_annualized_profit, type: Float #7日年化收益率

  index({symbol: 1, report_date: 1}, {unique: true, name: "symbol_report_date_index"})

  class << self

    # 获取最近的数据日期
    def get_latest_date
      return @get_latest_date if @get_latest_date
      memkey           = "Fund::CurrencyNetValue_get_latest_date_6"
      @get_latest_date = Rails.cache.fetch(memkey, :expires_in => 30.minutes) do
        date1 = Fund::Legacy::NavCur.order('PUBLISHDATE asc').last.PUBLISHDATE.to_date.to_s(:db)
        date2 = Fund::Legacy::NavCur.where(['PUBLISHDATE <> ?', date1]).order('PUBLISHDATE asc').last.PUBLISHDATE.to_date.to_s(:db)
        [date1, date2]
      end
    end
  end
end
