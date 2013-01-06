# -*- coding: utf-8 -*-
class Other::TrustCompany
  include Other::Abstract
  include Mongoid::Timestamps

  field :logo_image_url, type: String #（Logo图片)"
  field :legal_name, type: String #（法定名称）"
  field :name, type: String #（简称）"
  field :company_type, type: String #（公司类型）"
  field :credit_rating, type: String #（信用评级）"
  field :province, type: String #（省份）"
  field :city, type: String #（城市）"
  field :address, type: String #（地址）"
  field :postal, type: String #（邮编）"
  field :phone_number, type: String #（电话号码）"
  field :fax_number, type: String #（传真号码）"
  field :hot_line, type: String #（热线）"
  field :email, type: String #（客户电子邮箱）"
  field :website, type: String #（公司网址）"
  field :introduce, type: String #（公司简介）"
  field :state, type: Integer #数据状态  '0，ok  100，待更新  99，抓取错误',
  field :url, type: String #（抓取url）"

  scope :by_name, lambda { |name| where(:name => name) }
  has_many :trusts, :class_name => 'Other::Trust'

  index({name: 1}, {name: "name_index"})

  def latest_stat
    @tcs ||=Other::TrustCompanyStat.by_name(name).desc(:year).first
  end

  class << self

  end
end
