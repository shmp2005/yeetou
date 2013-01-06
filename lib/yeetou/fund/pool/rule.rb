# -*- coding: utf-8 -*-
# 某个基金池的指标
class Fund::Pool::Rule
  include Fund::Abstract
  include Mongoid::Timestamps

  field :definition_id, type: String #定义ID
  field :criterion_id, type: String  #指标ID
  field :operate, type: String       #操作码, equal, lte, gte, between, in, etc
  field :value, type: String         #操作值
  field :weigh, type: String         #权重
  field :sort, type: String          #排序

  belongs_to :definition, :class_name => "Fund::Pool::Definition", :foreign_key => :definition_id
  belongs_to :criterion, :class_name => "Fund::Pool::Criterion", :foreign_key => :criterion_id

end
