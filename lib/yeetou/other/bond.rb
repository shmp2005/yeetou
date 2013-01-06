#coding: utf-8
class Other::Bond
  include Other::Abstract
  include Mongoid::Timestamps

  field :bond_code, type: String                #债券组合代码
  field :bond_name, type: String                #债券名称
  field :short_name, type: String               #债券简称
  field :bond_type, type: String                #债券类型
  field :issue_start_date, type: Date      #发行起始日
  field :issue_end_date, type: Date        #发行终止日
  field :due_date, type: Date              #到期日期
  field :pay_interest_period, type: String      #付息周期
  field :nominal_rate, type: Float              #票面利率
  field :issued_by, type: String                #发行主体
  field :trade_banks, type: Array               #交易银行
  field :buy_counter, type: Integer, default: 0 #购买数

  index({bond_code: 1}, {unique: true, name: "bond_code_index"})
  index({bond_type: 1}, {name: "bond_type_index"})
  index({issue_start_date: 1}, {name: "issue_start_date_index"})
  index({issue_end_date: 1}, {name: "issue_end_date_index"})

  scope :latest_one_week, lambda { where(:issue_start_date => Date.today) }
  scope :by_term, lambda { |term| self.or(bond_code: term).or(bond_name: term).or(short_name: term) }
  scope :gt0_nominal_rate, lambda { gt(:nominal_rate => 0) }
  scope :top10_buy_counter, lambda { onsell_bonds.desc(:buy_counter).limit(10) }

  def cookie_key
    "#{self.class.name}_#{id}"
  end

  def tzp_url
    "/tz_search/bond_info?t=#{id}"
  end

  def is_on_sale?
    Date.today >= issue_start_date && Date.today <= issue_end_date
  end

  def name
    short_name
  end

  def fstatus
    today=Date.today
    if issue_end_date < today
      "售完"
    else
      if issue_start_date > today
        "即将发售"
      else
        "在售"
      end
    end
  end

  def features
    if issue_end_date.present? && issue_end_date >= Date.today &&
        nominal_rate.present? && nominal_rate >0
      f = %w[now]
    else
      f = %w[over]
    end

    if Other::Bond.cached_top10_by_buy_counter.include?(self.id)
      f << 'hot'
    end
    f
  end

  class << self
    def banks_by(s)
      case s.strip
        when '记帐' then
          %w[北京银行 工商银行 建设银行 南京银行 农业银行 中国银行 招商银行 民生银行 证券交易所]
        when '凭证' then
          %w[建设银行 工商银行 中国银行 农业银行 民生银行 中信银行 广发银行 招商银行 浦发银行
              兴业银行 华夏银行 交通银行 平安银行 光大银行 上海银行 宁波银行 北京银行 邮政储蓄银行]
        when '电子' then
          %w[北京银行 工商银行 建设银行 民生银行 南京银行 农业银行 中国银行 招商银行]
        else
          []
      end
    end

    def onsell_bonds
      self.gt0_nominal_rate.gte(:issue_end_date => Date.today.ymd).ne(:issue_end_date => '1900-01-01')
    end

    def over_bonds(args = {:year => "", :bond_type => ""})
      if args[:year]=="0" and args[:bond_type]=="0"
        return self.all
      end

      if args[:year]!="0" and args[:bond_type]=="0"
        start_date ="#{args[:year]}-01-01".to_date
        end_date   ="#{args[:year].to_i + 1}-01-01".to_date
        return self.gte(:issued_at => start_date).lt(:issued_at => end_date)
      end
      if args[:year]=="0"and args[:bond_type]!="0"
        return self.where(bond_type: args[:bond_type])
      end
      if args[:year]!="0" and args[:bond_type]!="0"
        start_date ="#{args[:year]}-01-01".to_date
        end_date   ="#{args[:year].to_i + 1}-01-01".to_date
        return self.where(bond_type: args[:bond_type]).gte(:issued_at => start_date).lt(:issued_at => end_date)
      end
    end

    def cached_top10_by_buy_counter
      memkey = "Other::bond.top10_by_buy_counter"
      Rails.cache.fetch(memkey, :expires_in => 10.minutes) do
        Other::Bond.top10_buy_counter.collect(&:id)
      end
    end
  end
end