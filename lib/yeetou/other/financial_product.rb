# -*- coding: utf-8 -*-
class Other::FinancialProduct
  include Other::Abstract
  include Mongoid::Timestamps

  #fields & index
  begin
    field :name, type: String                       #产品名称
    field :bank_id, type: String                    #发行银行
    field :bank_name, type: String                  #冗余字段，银行名称
    field :currency, type: String                   #币种
    field :product_type, type: String               #产品类型/投资类型
    field :initial_amount, type: Integer            #起购金额, 单位元
    field :expected_profit, type: Float             #预期收益率，%
    field :incremental_amount, type: Integer        #起购金额递增
    field :actual_profit, type: Float               #到期收益
    field :rate_compare, type: Float                # 同期利率比较
    field :breakeven_flag, type: Boolean            #是否保本
    field :issue_start_date, type: Date             #销售起始日期
    field :mortgage_flag, type: Boolean             #可否质押
    field :issue_end_date, type: Date               #销售截止日期
    field :period, type: Integer                    #管理期限, 单位 天
    field :profit_start_date, type: Date            #收益起始日期
    field :pay_interest_cycle, type: Integer        #付息周期
    field :profit_end_date, type: Date              #收益结束日期
    field :profit_type, type: String                #收益类型
    field :affiliated_currency, type: String        #附属币种
    field :redeem_flag, type: Boolean               #客户能否提前赎回
    field :affiliated_initial_amt, type: Float      #附属币种起始金额
    field :abort_flag, type: Boolean                #银行能否提前终止
    field :affiliated_initial_incr_amt, type: Float #附属币种起始金额
    field :region, type: String                     #销售地区
    field :management_fee, type: String             #产品管理费
    field :buy_condition, type: String              #申购条件
    field :redeem_condition, type: String           #赎回规定
    field :invest_goal, type: String                #投资目标/对象
    field :profit_desc, type: String                #投资方法说明
    field :risk_desc, type: String                  #风险提示
    field :grab_batch, type: Integer                #抓取批次
                                                    #数据状态'0，发布 10：数据缺失 20：数据异常 100，待抓取  99，抓取错误'
    field :state, type: Integer
    field :url                                      # 抓取的url，唯一
    field :buy_counter, type: Integer, default: 0   #购买数

    #set a default url as url has a unique index
    before_save :set_object_url

    index({url: 1}, {unique: true, name: "url_index"})
    index({name: 1}, {name: "name_index"})
    index({bank_name: 1}, {name: "bank_name_index"})
    index({breakeven_flag: 1, profit_type: 1}, {name: "breakeven_profit_index"})
    index({issue_start_date: 1}, {name: "issue_start_date_index"})
    index({created_at: 1}, {name: "created_at_index"})
    index({period: 1}, {name: "period_index"})
    index({expected_profit: 1}, {name: "expected_profit_index"})
    index({product_type: 1}, {name: "product_type_index"})
    index({initial_amount: 1}, {name: "initial_amount_index"})
    index({state: 1}, {name: "state_index"})
    index({expected_profit: 1, initial_amount: 1, state: 1}, {name: "rows_index"})
  end

  scope :rows, lambda { lte(:expected_profit => 10).where(:state => 0) }
  scope :by_name, lambda { |name| rows.where(:name => name) }
  scope :by_bank_name, lambda { |bank_name| rows.where(:bank_name => bank_name) }
  scope :exclude_banks, lambda { |banks| rows.nin(:bank_name => banks) }
  #p_min, p_max 单位天
  scope :by_period, lambda { |p_min, p_max| rows.gte(:period => p_min).lt(:period => p_max) }
  scope :by_expected_profit, lambda { |p_min, p_max| rows.gte(:expected_profit => p_min).lt(:expected_profit => p_max) }
  scope :gt0_expected_profit, lambda { rows.gt(:expected_profit => 0) }
  scope :by_initial_amount, lambda { |p_min, p_max| rows.gte(:initial_amount => p_min).lte(:initial_amount => p_max) }
  scope :by_product_type, lambda { |pt| rows.where(:product_type => pt) }
  scope :by_profit_type, lambda { |pt| rows.where(:profit_type => pt) }
  scope :by_breakeven, lambda { |breakeven| rows.where(:breakeven_flag => breakeven) }
  scope :latest_half_year, lambda { rows.gte(:issue_start_date => (Date.today - 6.month)) }
  scope :latest_one_year, lambda { rows.gte(:issue_start_date => (Date.today - 1.year)) }
  scope :previous_month, lambda { rows.gte(:issue_start_date => (Date.today - 1.month).beginning_of_month).lt(:issue_start_date => Date.today.beginning_of_month) }
  scope :on_sales, lambda { |adate=Date.today| rows.lte(:issue_start_date => adate).gte(:issue_end_date => adate) }
  scope :pre_sales, lambda { rows.gt(:issue_start_date => Date.today) }
  scope :pre_on_sales, lambda { rows.gte(:issue_end_date => Date.today) }
  scope :out_sales, lambda { rows.lt(:issue_end_date => Date.today) }
  scope :top10_buy_counter, lambda { pre_on_sales.desc(:buy_counter).limit(10) }

  def due_date
    profit_end_date
  end

  def cookie_key
    "#{self.class.name}_#{id}"
  end

  def is_on_sale?
    issue_end_date >= Date.today && issue_start_date <= Date.today
  end

  def is_pre_sale?
    issue_start_date > Date.today
  end

  def tzp_url
    "/tz_search/lccp_info?t=#{id}"
  end

  def breakeven
    if breakeven_flag.present?
      breakeven_flag ? "保本" : "不保本"
    end
  end

  def breakeven_and_profit
    if breakeven_flag.present?
      if breakeven_flag?
        case profit_type
          when '浮动收益' then
            "保本浮动收益"
          when '固定收益' then
            "保本保收益"
        end
      else
        case profit_type
          when '浮动收益' then
            "非保本浮动收益"
          when '固定收益' then
            "非保本固定收益"
        end
      end
    end
  end

  def redeem
    if redeem_flag.present?
      redeem_flag ? "是" : "否"
    end
  end

  #同期到月份，小于30天，按0计算
  def same_period_profit
    k      = (period/30).round
    memkey = "Other::FinancialProduct_#{k}m_profit"
    Rails.cache.fetch(memkey, :expires_in => 1.day) do
      data = Other::FinancialProduct.rows.by_period(period, period).gt0_expected_profit
      data.count==0 ? 0 : (data.sum(:expected_profit)*1.0/data.count).round(2)
    end
  end

  def same_product_profit
    memkey = "Other::FinancialProduct_#{product_type}_profit"
    Rails.cache.fetch(memkey, :expires_in => 1.day) do
      data = Other::FinancialProduct.rows.by_product_type(product_type).gt0_expected_profit
      data.count==0 ? 0 : (data.sum(:expected_profit)*1.0/data.count).round(2)
    end
  end

  def is_recommended
    @recommended ||= begin
      f_bank = Other::FinancialBank.by_name(bank_name).first
      if f_bank
        lytr = f_bank.latest_year_target_rate
        if lytr <= 0.0
          expected_profit > same_product_profit ? "推荐购买" : "不推荐"
        else
          m_bank = Other::FinancialBank.by_name("市场平均").first
          m_lytr =m_bank.latest_year_target_rate
          if expected_profit > same_product_profit && lytr > m_lytr
            "推荐购买"
          else
            "不推荐"
          end
        end
      end
    end
  end

  def features
    f =[]
    if Other::FinancialPool.where(id: self.id).first.present?
      f << 'pick'
    end
    f << 'new' if self.issue_start_date == Date.today
    if Other::FinancialProduct.cached_top10_by_buy_counter.include?(self.id)
      f << 'hot'
    end

    f << 'safe' if  breakeven_flag or profit_type=='固定收益'

    bank = Other::Bank.cached_by_name(self.bank_name)
    if bank
      f << (bank.nation_wide? ? 'nation' : 'local')
    end
    f << 'float' if  profit_type=='浮动收益'

    case period
      when (0...30*3) then
        f << 'term_short'
      when (30*3...30*6) then
        f << 'term_middle'
      when (30*6...30*10000) then
        f << 'term_long'
    end

    f
  end

  class << self

    def banks
      memkey = "Other::FinancialProduct_banks"
      Rails.cache.fetch(memkey, :expires_in => 1.day) do
        Other::FinancialProduct.rows.collect(&:bank_name).uniq.reject { |n| n.empty? }.sort
      end
    end

    def latest_year_avg_profit
      memkey = "Other::FinancialProduct_latest_year_avg_profit"
      Rails.cache.fetch(memkey, :expires_in => 1.day) do
        date = Date.today-1.year
        data = Other::FinancialProduct.rows.gte(:profit_start_date => date).ne(:expected_profit => 0.0)
        data.count.zero? ? 0 : (data.sum(&:expected_profit)*1.0/data.count).round(2)
      end
    end

    def cached_top10_by_buy_counter
      memkey = "Other::Lccp.top10_by_buy_counter"
      Rails.cache.fetch(memkey, :expires_in => 5.minutes) do
        Other::FinancialProduct.top10_buy_counter.collect(&:id)
      end
    end
  end
end


