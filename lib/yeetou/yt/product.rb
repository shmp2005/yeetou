# -*- coding: utf-8 -*-
class Yt::Product
  include Yt::Abstract
  include ToProduct

  field :code, type: String        #产品编码
  field :seq, type: String         #产品序号
  field :name, type: String        #产品名称
  field :short_name, type: String  #产品简称
  field :description, type: String #产品说明
  field :price, type: Float        #产品价格,单位元
  field :_id, type: String, default: -> { code }

  has_many :orders, :class_name => "Yt::Order", :foreign_key => "product_id"

  scope :by_code, lambda { |code| where(code: code) }

  validates_uniqueness_of :code, :message => "产品代码重复"

  def price_with_unit
    "#{price} 元"
  end
end
