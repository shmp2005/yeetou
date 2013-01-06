# -*- coding: utf-8 -*-
class Yt::OrderDetail
  include Yt::Abstract

  field :user_id, type: Integer
  field :order_id, type: String             #订单id
  field :tzp_id, type: String               #投资品id，如symbol
  field :tzp_type, type: String             #投资品类型，fund，trust，lccp和saving
  field :tzp_amount, type: Float            #此产品投资金额，单位元
  field :sequence, type: Integer            #用于排序
  field :tzp_ratio, type: Float             #投资额百分比
  field :tzp_profits, type: Array           #收益率
  field :tzp_earnings, type: Array          #投资收益额，单位元,对基金，有三个收益率，其他，只有一个
  field :memo, type: String                 #保存 存单的存期
  field :actual_amount_by_user, type: Float #用户填写的到期实际金额

  belongs_to :order, :class_name => "Yt::Order", :foreign_key => :order_id

  TYPE_FIXED = %w[Other::Trust Other::Saving Other::FinancialProduct]
  TYPE_RISK  =%w[Fund::Fund]

  def is_fixed?
    TYPE_FIXED.include?(tzp_type)
  end

  def is_risk?
    TYPE_RISK.include?(tzp_type)
  end

  def tzp
    if @cached_tzp.nil?
      @cached_tzp = tzp_type.constantize.where(id: tzp_id).first
    end
    @cached_tzp
  end

  def decorator
    "#{tzp_type}Decorator".constantize.find(tzp_id)
  end

  #用于render partial
  def partial_name
    case tzp_type
      when "Other::FinancialProduct" then
        "lccp"
      else
        tzp_type.split("::").last.underscore
    end
  end

  def tzp_url
    @t_url ||= tzp_type.constantize.find(tzp_id).tzp_url
  end

  def total_amounts
    tzp_earnings.map { |e| (e + tzp_amount).round }
  end

  #计算实际的收益，
  #基金按累计净值来算收益率
  #其他把收益率日化，再乘以已经投资的天数计算
  def actual_amount(date=Date.today, from=nil)
    ((actual_profit(date, from)/100.0 + 1)*tzp_amount).round
  end

  def actual_profit(date=Date.today, from=nil)
    if is_fixed?
      tzp_profits[0].round(2)
    else
      date1 = from || self.order.tz_date
      unv1  = decorator.get_net_value(date1)[:total_unv]||0
      unv2  = decorator.get_net_value(date)[:total_unv]||0

      if unv1.zero?
        0
      else
        ((unv2 - unv1)*100/unv1).round(2)
      end
    end
  end
end
