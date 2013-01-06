# -*- coding: utf-8 -*-
class Other::TrustPool
  include Other::Abstract
  include Mongoid::Timestamps

  field :pool_type, type: String #精选类型，如12月、18月、24月、30月（含）以上
  field :pool_name, type: String #池子名称
  field :trust_id, type: String
  field :memo                    #备注

  belongs_to :trust, :class_name => 'Other::Trust'

  index({ trust_id: 1, pool_type: 1 }, { name: "trust_id_pool_type_index", unique: true })

  scope :by_pool_type, lambda { |pool_type| where(pool_type: pool_type) }

  Other::TrustBacklog::POOL_DEFINITION.keys.map { |e| scope e, lambda { by_pool_type(e) } }

  def to_backlog
    backlog = Other::TrustBacklog.where(pool_type: pool_type, trust_id: trust_id).first
    backlog.update_attributes state: 10 if backlog

    self.delete
  end

  class << self

    def daily_update
      log("移除过期信托")
      #移除过期信托
      out_ids = Other::Trust.pre_on_sales.collect(&:id)
      Other::TrustPool.nin(id: out_ids).delete_all
    end

    #新添加一个信托入池
    def add_new(pool_type, trust_id, memo)
      trust = self.where(pool_type: pool_type, :trust_id => trust_id).first
      if trust.nil?
        self.create! pool_type: pool_type,
                     pool_name: Other::TrustBacklog::POOL_DEFINITION[pool_type.to_sym],
                     trust_id:  trust_id,
                     memo:      memo
        log("#{pool_type}, #{trust_id} added with memo #{memo}")
      end
    end
  end
end

