# -*- coding: utf-8 -*-
class Other::TzSearch
  include Other::Abstract
  include Mongoid::Timestamps

  #fields & index
  begin
    field :user_id, type: String     #用户ID
    field :tz_amt, type: String      #投资金额
    field :tz_month, type: String    #投资月份
    field :tz_date, type: String     #投资开始日期
    field :ip, type: String          #ip
    field :agent, type: String       #request user agent
    field :search_type, type: String #搜索类型
    field :params, type: String #其他参数
  end

  class << self
    def log(search_type, rolable, agent, params)
      uid = rolable.nil? ? nil : rolable.user.id
      Other::TzSearch.create! tz_amt:      params[:tz_amt],
                              tz_month:    params[:tz_month],
                              tz_date:     params[:tz_date],
                              ip:          params[:ip],
                              search_type: search_type,
                              params:      params.to_query,
                              user_id:     uid,
                              agent:       agent
    end
  end
end
