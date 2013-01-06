# -*- coding: utf-8 -*-
class Yt::NextNumber
  include Yt::Abstract

  field :code, type: String                #产品编码, YT001
  field :last_used_date, type: Date        #最后使用日期
  field :number, type: Integer, default: 1 #订单序号

  validates_uniqueness_of :code, :message => "产品代码重复"

  class << self

    #获取下一个订单号码
    def next_order_number(code)
      p = Yt::Product.where(code: code).first
      raise YeetouException, "无效的产品代码#{code} in Yt::Product" if p.nil?

      [Date.today.ymd(''), p.seq, next_number(code), Rails.env=='development' ? "D" : ''].join('')
    end

    #取得下一个序号
    def next_number(code)
      nu = Yt::NextNumber.where(code: code).first
      raise YeetouException, "无效的产品代码#{code} in Yt::NextNumber" if nu.nil?

      today = Date.today

      number = nu.number
      if today == nu.last_used_date
        nu.number += 1
      else
        number    = 1
        nu.number = 2
      end
      nu.last_used_date = today
      nu.save

      number.to_s.rjust(3, '0')
    end
  end
end
