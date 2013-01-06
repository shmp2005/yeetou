# -*- coding: utf-8 -*-
# 基金指标定义
class Fund::Pool::Criterion
  include Fund::Abstract
  include Mongoid::Timestamps

  field :category, type: String    #指标大类
  field :subcategory, type: String #指标小类
  field :code, type: String        #代码
  field :name, type: String        #名称

  scope :by_category_code, lambda { |cat, code| where(category: cat, code: code) }

end
