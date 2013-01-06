# -*- coding: utf-8 -*-
class Other::Cpi
  include Other::Abstract

  field :publish_month, type: String  #数据日期
  field :nation_current, type: Float  #全国当月
  field :nation_yoy, type: Float      #全国同比增长
  field :nation_mom, type: Float      #全国环比增长
  field :nation_sum, type: Float      #全国累计

  field :city_current, type: Float    #城市当月
  field :city_yoy, type: Float        #城市同比增长
  field :city_mom, type: Float        #城市环比增长
  field :city_sum, type: Float        #城市累计

  field :country_current, type: Float #农村当月
  field :country_yoy, type: Float     #农村同比增长
  field :country_mom, type: Float     #农村环比增长
  field :country_sum, type: Float     #农村累计

  class << self
    def latest_yoy_sum
      cpi = Other::Cpi.desc(:publish_month).limit(1).first
      (cpi.nation_sum - 100).round(2)
    end
  end
end


