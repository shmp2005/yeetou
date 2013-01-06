# -*- coding: utf-8 -*-
class Other::Outlet
  include Other::Abstract
  include Mongoid::Timestamps

  field :bank_id, type: String #银行
  field :region_code, type: String #地区
  field :outlet_type, type: String #类型，ATM or 柜台
  field :name, type: String # 名称
  field :address, type: String #地址
  field :phone_number, type: String #电话
  field :working_time, type: String #营业时间
  field :atm_function, type: String #ATM的功能
  field :map_url, type: String #地图url
  field :url, type: String #抓取的url
  field :state, type: Integer #数据状态  '0，ok  100，待更新  99，抓取错误'

  belongs_to :bank, :class_name => "Other::Bank"
  belongs_to :region, :class_name => "Other::Region"

  scope :rows, lambda { where(:state => 0) }
  scope :atms, lambda { rows.where(:outlet_type => 'atm') }
  scope :counters, lambda { rows.where(:outlet_type => 'out') }
  scope :wrongs, lambda { where(address: /\.\.\.$/) }

  class << self

  end
end