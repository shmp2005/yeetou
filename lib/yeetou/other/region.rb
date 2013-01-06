# -*- coding: utf-8 -*-
class Other::Region
  include Other::Abstract

  field :parent_code, type: Integer, default: 0
  field :code, type: Integer
  field :name, type: String
  field :first_spell, type: String

  scope :provinces, lambda { where(:parent_code => 1) }
  scope :by_code, lambda { |code| where(:code => code) }
  scope :by_name, lambda { |name| where(name: name) }

  def spell_and_name
    "#{first_spell} #{name}"
  end

  def parent
    self.class.where(:code => self.parent_code).first
  end

  def children
    self.class.where(:parent_code => self.code)
  end

  class << self
  end
end
