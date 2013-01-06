# -*- coding: utf-8 -*-
class Other::ProductType
  include Other::Abstract

  field :parent_code, type: String
  field :code, type: String
  field :origin_code, type: String
  field :currency, type: String, default: "CNY"
  field :name, type: String
  field :duration, type: String
  field :level, type: Integer
  field :path, type: String
  field :active, type: Boolean, default: true
  field :_id, type: String, default: -> { code }

  index({ code: 1 }, { unique: true, name: "code_index" })

  has_many :interests, :class_name => "Other::Interest"
  has_many :savings, :class_name => "Other::Saving"
  has_one :product_detail, :class_name => "Other::ProductDetail"

  scope :by_active, lambda { where(:active => true) }
  scope :by_name, lambda { |name| where(:name => name) }
  scope :cny, lambda { where(:currency => 'CNY') }
  scope :active_cny_level1, lambda { cny.by_active.where(:level => 1).asc(:code) }
  scope :active_cny_periods, lambda { |code| cny.by_active.where(:parent_code => code).asc(:code) }
  scope :active_cny_product, lambda { |code| cny.by_active.where(:code => code) }
  scope :fixed_will_periods, lambda { active_cny_periods("310") }
  scope :notify_periods, lambda { active_cny_periods("410") }

  def parent
    @_parent ||= self.class.by_active.where(:code => self.parent_code).first
  end

  def children
    @_children ||= self.class.by_active.where(:parent_code => self.code).asc(:code)
  end

  def locale_currency
    case currency
      when "CNY" then
        "人民币"
      else
        currency
    end
  end

  class << self

    # zz,zl,lz
    def calc_year(year, code)
      return Hash.new unless %w[210 220 230].include?(code.to_s)

      hy = case code.to_s
             when "210" then
               Hash['216', 5, '215', 3, '214', 2, '213', 1]
             when "220" then
               Hash['223', 5, '222', 3, '221', 1]
             when "230" then
               Hash['233', 5, '232', 3, '231', 1]
           end
      hr =Hash.new
      hy.keys.collect { |k| hr[k]=0 }

      hyk = hy.keys
      hyv =hy.values
      hyv.each do |yv|
        m = year/yv

        #puts "m=#{m}, year=#{year}, yv=#{yv}"

        #zl
        if code.to_s=='230' or code.to_s =='220'
          if m > 0
            hr[hyk[hyv.index(yv)]] +=1
            year                   -= yv
            break
          end
        else
          hr[hyk[hyv.index(yv)]] +=m
          year                   %= yv
        end

        #puts "m=#{m};year=#{yv}"
      end
      hr.merge!(calc_year(year, '210')) if code.to_s=='220' && year >0

      hr.reject { |k, v| v==0 }
    end

    #zz only
    def calc_month(month, day, notify=false)
      hm =Hash['212', 6, '211', 3]
      hr =Hash.new
      hm.keys.collect { |k| hr[k]=0 }

      hmk = hm.keys
      hmv =hm.values
      hmv.each do |mv|
        m = month/mv

        hr[hmk[hmv.index(mv)]] +=m if m>0

        month %= mv
        #puts "m=#{m};month=#{mv}"
      end
      k     = notify ? '412' : '111'
      hr[k] = month*30 + day

      hr.reject { |k, v| v==0 }
    end
  end
end

