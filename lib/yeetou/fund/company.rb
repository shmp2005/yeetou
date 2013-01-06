# -*- coding: utf-8 -*-
# 基金公司
class Fund::Company

  include Fund::Abstract

  has_many :funds, :class_name => 'Fund::Fund', :foreign_key => 'company_code'

  field :o_id, type: Integer
  field :symbol, type: String
  field :name, type: String
  field :code, type: String
  field :_id, type: String, default: -> { code }
  field :url, type: String
  field :report_date, type: Date
  field :department_setting, type: String
  field :contact_name, type: String
  field :phone_number, type: String
  field :fax_number, type: String

  def short_name
    name.gsub(/管理有限公司/, "")
  end

  def full_url
    url.start_with?("http") ? url : "http://#{url}"
  end
end
