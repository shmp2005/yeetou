# -*- coding: utf-8 -*-
class Yt::OrderProfit
  include Yt::Abstract

  field :order_id, type: String #订单id
  field :last_date, type: Date  #最后更新日期
  field :profits, type: Array   #[[date1, profit1], [date2, profit2], ... ]

  belongs_to :order, :class_name => "Yt::Order", :foreign_key => :order_id

end
