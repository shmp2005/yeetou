# -*- coding: utf-8 -*-
# 基金池定义
class Fund::Pool::Definition
  include Fund::Abstract
  include Mongoid::Timestamps

  field :code, type: String        #池子代码，f01,f02...
  field :name, type: String        #池子名称
  field :benchmark, type: String   #池子基准
  field :description, type: String #池子说明
  field :created_by, type: String  #创建人

  scope :by_code, lambda { |code| where(code: code) }

  has_many :rules, :class_name => "Fund::Pool::Rule"
  has_many :backlogs, :class_name => "Fund::Backlog"
  has_many :fund_pools, :class_name => "Fund::FundPool"
end
