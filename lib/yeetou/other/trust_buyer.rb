# -*- coding: utf-8 -*-
class Other::TrustBuyer
  include Other::Abstract
  include Mongoid::Timestamps

  begin
    field :user_id, type: String
    field :trust_id, type: String
    field :trust_name, type: String
    field :buy_number, type: String #购买电话
    field :buy_mail, type: String #购买邮箱
  end

  belongs_to :trust, :class_name => "Other::Trust"

  def name
    id.to_s
  end
end