# -*- coding: utf-8 -*-
class Other::TzPurchase
  include Other::Abstract
  include Mongoid::Timestamps

  #fields & index
  begin
    field :user_id, type: Integer                        #用户ID
    field :tz_type, type: String                         #投资品类型
    field :tz_id, type: String                           #投资品ID
    field :purchased_flag, type: Boolean, default: false #实际购买flag
    field :purchased_at, type: DateTime                  #实际购买日期
    field :ignored_flag, type: Boolean, default: false   #没有购买，则忽略
    field :ignored_at, type: DateTime                    #忽略日期
    field :buy_counter, type: Integer, default: 1        #点击购买次数
    field :ip, type: String
    field :agent, type: String
    field :action_type, type: String                     #view or buy

    index({user_id: 1, tz_type: 1, tz_id: 1}, {unique: true, name: "user_tz_index"})

    scope :views, lambda { where(action_type: 'view') }
    scope :buys, lambda { where(action_type: 'buy') }
    scope :user_by, lambda { |user_id| where(user_id: user_id) }
    scope :tz_by, lambda { |tz_type, tz_id| buys.where(tz_type: tz_type, tz_id: tz_id) }
    scope :views_by, lambda { |tz_type, tz_id| views.where(tz_type: tz_type, tz_id: tz_id) }
    scope :pendings, lambda { |user_id| buys.user_by(user_id).where(purchased_flag: false, ignored_flag: false) }
  end

  def purchase
    self.update_attributes purchased_flag: true, purchased_at: Time.now
  end

  def ignore
    self.update_attributes ignored_flag: true, ignored_at: Time.now
  end

  def tzp_url
    case tz_type
      when "Fund::Fund" then
        "/funds/#{tz_id}"
      when "Other::Trust" then
        "/tz_search/trust_info?t=#{tz_id}"
      when "Other::FinancialProduct" then
        "/tz_search/lccp_info?t=#{tz_id}"
      when "Other::Saving" then
        "/tz_search/deposit_info?t=#{tz_id}"
    end
  end

  def tzp
    @tzp ||= begin
      tz_type.constantize.find(tz_id)
    end
  end

  class << self
    def buy_more(user, tz_type, tz_id, ip=nil, agent=nil)
      tz = user_by(user.user.id).tz_by(tz_type, tz_id).first
      if tz
        tz.buy_counter += 1
        tz.save
      else
        tz = create user_id:     user.user.id,
                    tz_type:     tz_type,
                    tz_id:       tz_id,
                    buy_counter: 1,
                    ip:          ip,
                    agent:       agent,
                    action_type: 'buy'
      end
      tz
    end

    #记录用户浏览的商品
    def view_more(rolable, tz_type, tz_id, ip=nil, agent=nil)
      uid = rolable.nil? ? nil : rolable.user.id
      self.create user_id:     uid,
                  tz_type:     tz_type,
                  tz_id:       tz_id,
                  ip:          ip,
                  agent:       agent,
                  action_type: 'view'
    end
  end
end
