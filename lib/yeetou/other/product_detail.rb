# -*- coding: utf-8 -*-
class Other::ProductDetail
  include Other::Abstract

  field :code, type: String                 #产品编码
  field :name, type: String                 #产品名称
  field :definition, type: String           #产品定义
  field :periods, type: Array               #存期列表
  field :base_rates, type: Array            #对应基准利率
  field :min_amount, type: Integer          #起存金额
  field :max_amount, type: Integer          #最大金额
  field :adv_withdraw_flag, type: Boolean   #是否可以提前支取
  field :adv_withdraw_desc, type: String    #提前支取说明
  field :auto_deposit_flag, type: Boolean   #是否可以自动转存
  field :agreed_deposit_flag, type: Boolean #是否可以约定转存
  field :memo, type: String                 #备注
  field :_id, type: String, default: -> { code }

  index({ code: 1 }, { unique: true, name: "code_index" })

  belongs_to :product_type, :class_name => "Other::ProductType", :foreign_key => :code

  class << self
  end
end

