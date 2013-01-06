# -*- coding: utf-8 -*-
class Fund::FundPool
  include Fund::Abstract

  include Mongoid::Timestamps

  field :definition_id, type: String            #池子ID
  field :symbol, type: String
  field :benchmark, type: String                #比较基准
  field :score, type: Float                     #打分分数
  field :seq_number, type: Integer, default: 99 #排序

  #0, 确认精选，10，新数据，未确认和排除，99，已排除
  field :state, type: Integer

  belongs_to :fund, :class_name => 'Fund::Fund', :foreign_key => :symbol
  belongs_to :definition, :class_name => 'Fund::Pool::Definition', :foreign_key => :definition_id

  STATES = Hash[0, '确认', 10, '新数据', 99, '已排除']

  scope :rows, lambda { self.in(state: [0, 10]) }
  scope :pending, lambda { where(state: 10) }
  scope :excluded, lambda { where(state: 99) }

  def confirmed?
    state == 0
  end

  def excluded?
    state == 99
  end

  def pending?
    state == 10
  end

  class << self
    def f01
      by_code(:f01)
    end

    def f02
      by_code(:f01)
    end

    def by_code(p_code)
      Fund::Pool::Definition.by_code(p_code).first.fund_pools
    end
  end
end


