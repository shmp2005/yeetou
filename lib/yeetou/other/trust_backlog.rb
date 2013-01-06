# -*- coding: utf-8 -*-
class Other::TrustBacklog
  include Other::Abstract
  include Mongoid::Timestamps

  field :pool_type, type: String #精选类型，如12月、18月、24月、30月（含）以上
  field :pool_name, type: String #池子名称
  field :trust_id, type: String
  field :memo                    #备注

  #0, 已确认，10，新数据，99，已排除
  field :state, type: Integer

  belongs_to :trust, :class_name => 'Other::Trust'

  index({ trust_id: 1, pool_type: 1 }, { name: "trust_id_pool_type_index", unique: true })

  POOL_DEFINITION = {
      t12: '12个月',
      t18: '18个月',
      t24: '24个月',
      t30: '30个月(含)以上'
  }

  STATES = Hash[0, '已确认', 10, '新数据', 99, '已排除']

  scope :confirmed, lambda { where(state: 0) }
  scope :pending, lambda { where(state: 10) }
  scope :excluded, lambda { where(state: 99) }
  scope :by_pool_type, lambda { |pool_type| where(pool_type: pool_type) }

  POOL_DEFINITION.keys.map { |e| scope e, lambda { by_pool_type(e) } }

  def confirmed?
    state == 0
  end

  def excluded?
    state == 99
  end

  def pending?
    state == 10
  end

  def exclude
    update_attributes state: 99
  end

  def confirm
    update_attributes state: 0
    Other::TrustPool.add_new(pool_type, trust_id, memo)
  end

  class << self

  end
end


