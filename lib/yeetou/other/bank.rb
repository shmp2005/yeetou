# -*- coding: utf-8 -*-
# http://bank.eastmoney.com/Bank3080185.html
class Other::Bank
  include Other::Abstract

  field :first_spell, type: String                  #首字母
  field :abbr, type: String                         #英文简称
  field :name, type: String                         #简称
  field :alias_names, type: Array                   #别称,用于多个名称匹配
  field :legal_name, type: String                   #全称
  field :english_name, type: String                 #英文名称
  field :introduce, type: String                    #简介
  field :logo_image_path, type: String              #Logo图片路径
  field :small_logo_path, type: String              #Logo小图片路径
  field :establish_date, type: String               #成立日期
  field :register_capital, type: String             #注册资本
  field :register_address, type: String             #注册地址
  field :postal, type: String                       #邮编
  field :contact_email, type: String                #客服邮箱
  field :contact_fax, type: String                  #传真
  field :business_scope, type: String               #经营范围
  field :bank_type, type: String                    #银行性质
  field :legal_person, type: String                 #法人
  field :president, type: String                    #行长
  field :online_bank, type: String                  #网上银行
  field :swift_code, type: String                   #国际代码
  field :hot_line, type: String                     #热线
  field :vip_line, type: String                     #vip 热线
  field :credit_card_line, type: String             #信用卡热线
  field :stock_rights, type: String                 #股权代码
  field :hq_address, type: String                   #总部地址
  field :website, type: String                      #网站
  field :saving_flag, type: Boolean, default: false # 是否有存单信息
  field :url, type: String                          #抓取的地址
  field :state, type: Integer, default: 100

  has_many :interests, :class_name => "Other::Interest"
  has_many :savings, :class_name => "Other::Saving"

  scope :valid_banks, lambda { where(:state => 0) }
  scope :by_name, lambda { |name| valid_banks.where(:name => name) }
  scope :by_alias_names, lambda { |name| valid_banks.where(:alias_names => name) }
  scope :by_abbr, lambda { |abbr| valid_banks.where(:abbr => abbr) }
  scope :with_savings, lambda { valid_banks.where(:saving_flag => true).asc(:first_spell, :name) }
  scope :nation_wide, lambda { valid_banks.in(:bank_type => %w[国有银行 股份制银行]) }
  scope :local_wide, lambda { valid_banks.nin(:bank_type => %w[国有银行 股份制银行]) }
  scope :four_biggest, lambda { valid_banks.in(name: %w[中国银行 工商银行 农业银行 建设银行]) }

  def spell_and_name
    "#{first_spell} #{name}"
  end

  def nation_wide?
    %w[国有银行 股份制银行].include?(self.bank_type)
  end

  #计算活期利率
  def calc_current(days, amt)
    calc_common(111, days, amt)
  end

  #计算通知存款
  def calc_notify(code, days, amt, cr=nil)
    raise YfsException, "无效的通知存款代码(#{code})。[411 | 412]" unless [411, 412].include?(code.to_i)
    calc_common(code, days, amt, {cr: cr})
  end

  #整存整取
  def calc_fixed_zz(code, amt, cr=nil)
    raise YfsException, "无效整存整取存期代码" unless (211..216).to_a.include?(code.to_i)
    factor   = case code.to_i
                 when 211 then
                   0.25
                 when 212 then
                   0.5
                 when 213 then
                   1.0
                 when 214 then
                   2.0
                 when 215 then
                   3.0
                 when 216 then
                   5.0
               end
    rate     = cr || rate_by(code)
    interest = (amt*rate*factor).round(2)
    {rate: rate, interest: interest, total: (amt+interest).round(2)}
  end

  #零存整取
  def calc_fixed_lz(code, amt, cr=nil)
    raise YfsException, "无效零存整取存期代码(#{code})" unless (221..223).to_a.include?(code.to_i)
    factor   = case code.to_i
                 when 221 then
                   1.0
                 when 222 then
                   3.0
                 when 223 then
                   5.0
               end
    rate     = cr || rate_by(code)
    interest = ((1+12*factor)*(rate*factor)*amt/2.0).round(2)
    {rate: rate, interest: interest, total: (amt*factor*12 + interest).round(2)}
  end

  #整存零取
  def calc_fixed_zl(code, frequency, amt, cr=nil)
    raise YfsException, "无效整存零取存期代码(#{code})" unless (231..233).to_a.include?(code.to_i)
    raise YfsException, "无效支取频率(#{frequency})" unless %w[monthly quarterly semiyearly yearly].include?(frequency.to_s)
    factor  = case code.to_i
                when 231 then
                  1.0
                when 232 then
                  3.0
                when 233 then
                  5.0
              end
    factor2 =case frequency
               when 'monthly' then
                 12
               when 'quarterly' then
                 4
               when 'semiyearly' then
                 2
               when 'yearly' then
                 1
             end
    times   = factor * factor2
    avg_amt = (amt / times).round(2)

    rate     = cr || rate_by(code)
    #puts "rate=#{rate}; avg_amt=#{avg_amt}"
    interest = ((amt + avg_amt)*0.5*times*(12/factor2)*(rate/12.0)).round(2)
    {rate: rate, interest: interest, total: (amt + interest).round(2)}
  end

  #存本取息
  def calc_fixed_cbqx(code, amt, cr=nil)
    raise YfsException, "无效存本取息存期代码(#{code})" unless (241..243).to_a.include?(code.to_i)
    factor   = case code.to_i
                 when 241 then
                   1
                 when 242 then
                   3
                 when 243 then
                   5
               end
    rate     = cr || rate_by(code)
    interest = (amt*rate*factor).round(2)
    {rate: rate, interest: interest, total: (amt + interest).round(2)}
  end

  #教育储蓄
  def calc_fixed_jy(code, amt, cr=nil)
    raise YfsException, "无效教育储蓄存期代码(#{code})" unless (251..253).to_a.include?(code.to_i)
    rate   =0
    factor = case code.to_i
               when 251 then
                 rate = rate_by(213)
                 1.0
               when 252 then
                 rate = rate_by(215)
                 3.0
               when 253 then
                 rate = rate_by(216)
                 6.0
             end
    rate   = cr || rate

    interest = ((1+12*factor)*(rate*factor)*amt/2.0).round(2)
    {rate: rate, interest: interest, total: (amt*factor*12 + interest).round(2)}
  end

  #计算定活两便
  def calc_fixed_will(days, amt, cr=nil)
    case days
      when (0...90) then
        calc_current(days, amt)
      when (91...180) then
        calc_common(211, days, amt, {discount: 0.6, cr: cr})
      when (181...365) then
        calc_common(212, days, amt, {discount: 0.6, cr: cr})
      else
        calc_common(213, days, amt, {discount: 0.6, cr: cr})
    end
  end

  def calc_common(code, days, amt, opt={discount: 1.0, cr: nil})
    rate     = opt[:cr] || rate_by(code)
    discount = opt[:discount] || 1.0
    interest = (amt*rate* discount*days/365.0).round(2)
    {rate: rate, interest: interest, total: (amt + interest).round(2)}
  end

  def rate_by(code)
    interest=interests.by_product_code(code).first
    if interest.nil?
      c_rate = Other::Interest.latest_china_rate(code).first
      interest.nil? ? 0 : c_rate.rate/100.0
    else
      interest.rate/100.0
    end
  end

  class << self

    def max_rate_banks_by_code(code)
      max_date = Other::Interest.max(:published_at)
      max_rate = Other::Interest.by_product_code(code).where(:published_at => max_date).max(:rate)
      bank_ids = Other::Interest.by_product_code(code).where(:published_at => max_date, :rate => max_rate).limit(6)
      {max_date: max_date, max_rate: max_rate, banks: self.in(:id => bank_ids.collect(&:bank_id))}
    end

    def cached_by_name(name)
      memkey = "Other::Bank.by_name_#{name}"
      Rails.cache.fetch(memkey, :expires_in => 1.week) do
        Other::Bank.by_name(name).first
      end
    end
  end
end
