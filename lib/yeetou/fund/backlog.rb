# -*- coding: utf-8 -*-
class Fund::Backlog
  include Fund::Abstract
  include Mongoid::Timestamps

  field :definition_id, type: String #池子ID
  field :symbol, type: String
  field :benchmark, type: String     #比较基准
  field :score, type: Float          #打分分数

  #0, 进入池子，10，新数据，未确认
  field :state, type: Integer

  belongs_to :fund, :class_name => 'Fund::Fund', :foreign_key => :symbol
  belongs_to :definition, :class_name => 'Fund::Pool::Definition', :foreign_key => :definition_id

  STATES = Hash[0, '已入池', 10, '新数据']
  scope :pending, lambda { where(state: 10) }

  def confirmed?
    state == 0
  end

  def pending?
    state == 10
  end

end


