# -*- coding: utf-8 -*-
class Other::Trust
  include Other::Abstract
  include Mongoid::Timestamps

  #fields & index
  begin
    field :trust_company_id, type: String    #信托公司
    field :name, type: String                #产品名称
    field :project_manager, type: String     #项目经理
    field :trust_type, type: String          #产品类型
    field :currency, type: String            #币别
    field :management_type, type: String     #投资管理类型
    field :issue_start_date, type: Date      #发行日期
    field :issue_end_date, type: Date        #发行日期
    field :sell_target, type: String         #发售对象
    field :issue_scale, type: String         #发行规模
    field :initial_amount, type: Integer     #门槛金额
    field :period, type: Integer             #最短期限
    field :period_type, type: String         #期限类型
    field :expected_profit, type: Float      #预期年收益率
    field :actual_profit, type: Float        #实际收益率
    field :invest_method, type: String       #投资方式
    field :invest_target, type: String       #投资目标
    field :trust_fee_rate, type: Float       #资金托管费率
    field :sell_fee_rate, type: Float        #销售手续费率
    field :establish_date, type: Date        #成立日期
    field :establish_scale, type: Integer    #成立规模
    field :profit_type, type: String         #收益类型
    field :breakeven_flag, type: Boolean     #是否保本
    field :due_date, type: Date              #到期日期
    field :issue_region, type: String        #发行地区
    field :capital_usage, type: String       #资金使用情况
    field :related_info, type: String        #相关信息
    field :yeetou_rating, type: String       #易投评价
    field :yeetou_risk_control, type: String #易投风险控制
    field :mortgage_ratio, type: Float       #抵押率
    field :sell_state, type: Integer         #销售状态 # 0，预约，10 在售，20 售罄，30 运行，99 结束

                                                  #数据状态  '0，发布 10：数据缺失 20：数据异常 100，待抓取  99，抓取错误'
    field :state, type: Integer
    field :url, type: String                      #抓取的URL
    field :buy_counter, type: Integer, default: 0 #购买数

    #set a default url as url has a unique index
    before_save :set_object_url

    index({url: 1}, {unique: true, name: "url_index"})
    index({name: 1}, {name: "name_index"})
    index({issue_start_date: 1}, {name: "issue_start_date_index"})
    index({expected_profit: 1}, {name: "expected_profit_index"})
    index({invest_target: 1}, {name: "invest_target_index"})
    index({state: 1}, {name: "state_index"})

    belongs_to :trust_company, :class_name => 'Other::TrustCompany'
  end

  scope :rows, lambda { where(:state => 0) }
  scope :by_name, lambda { |name| where(:name => name) }
  scope :gt0_expected_profit, lambda { rows.gt(:expected_profit => 0) }
  # unit is 万
  scope :by_initial_amount, lambda { |p_min, p_max| rows.gte(:initial_amount => p_min).lte(:initial_amount => p_max) }
  scope :issue_date_in, lambda { |adate| rows.gte(:issue_start_date => adate.beginning_of_month).lt(:issue_start_date => (adate+1.month).beginning_of_month) }
  scope :latest_one_year, lambda { rows.gte(:issue_start_date => (Date.today - 1.year)) }
  scope :latest_one_month, lambda { rows.gte(:issue_start_date => (Date.today - 1.month)) }
  scope :latest_half_month, lambda { rows.gte(:issue_start_date => (Date.today - 15.days)) }
  scope :latest_one_week, lambda { rows.gte(:issue_start_date => (Date.today - 1.week)) }
  scope :by_expected_profit, lambda { |p_min, p_max| rows.gte(:expected_profit => p_min).lte(:expected_profit => p_max) }
  scope :by_period, lambda { |p_min, p_max| rows.gte(:period => p_min).lte(:period => p_max) }
  scope :by_invest_target, lambda { |invest_target| rows.where(:invest_target => invest_target) }
  scope :by_invest_method, lambda { |invest_method| rows.where(:invest_method => invest_method) }
  scope :by_sell_state, lambda { |sell_states| rows.in(:sell_state => sell_states) }
  scope :by_company, lambda { |trust_company_id| rows.in(:trust_company_id => trust_company_id) }
  scope :hots, lambda { latest_half_month.by_expected_profit(9, 12).by_invest_target('基础设施').desc(:expected_profit) }
  scope :top10_buy_counter, lambda { rows.desc(:buy_counter).limit(10) }
  scope :pre_on_sales, lambda { by_sell_state([0, 10]) }

  SELL_STATE = [[0, '预约'], [10, '在售'], [20, '售罄'], [30, '运行'], [99, '结束']]

  def sell_state_text
    ss = SELL_STATE.find { |e| e.first==sell_state }
    ss.last if ss.present?
  end

  def tzp_url
    "/tz_search/trust_info?t=#{id}"
  end

  def cookie_key
    "#{self.class.name}_#{id}"
  end

  def features
    f = []
    if Other::Trust.cached_hots.include?(self.id)
      f << 'pick'
    end
    f << 'new' if issue_start_date == Date.today
    if Other::Trust.cached_top10_by_buy_counter.include?(self.id)
      f << 'hot'
    end

    cname = trust_company.name
    if Other::Trust.cached_big_companies.include?(cname)
      f << 'big'
    end
    case self.invest_target
      when '房地产' then
        f << 'house'
      when '工商企业' then
        f << 'enterprise'
      when '基础设施' then
        f << 'base'
      when '金融市场' then
        f << 'finance'
    end
    f
  end

  class << self

    def latest_one_year_avg_profit
      memkey = "Other::Trust_latest_one_year_avg_profit"
      Rails.cache.fetch(memkey, :expires_in => 1.day) do
        trusts = Other::Trust.latest_one_year.gt0_expected_profit
        (trusts.avg(&:expected_profit)||0).round(2)
      end
    end

    def cached_hots
      memkey = "Other::Trust.hots"
      Rails.cache.fetch(memkey, :expires_in => 10.minutes) do
        Other::Trust.hots.limit(10).collect(&:id)
      end
    end

    def cached_top10_by_buy_counter
      memkey = "Other::Trust.top10_by_buy_counter"
      Rails.cache.fetch(memkey, :expires_in => 10.minutes) do
        Other::FinancialProduct.top10_buy_counter.collect(&:id)
      end
    end

    def cached_big_companies
      memkey = "Other::Trust.big_companies"
      Rails.cache.fetch(memkey, :expires_in => 10.minutes) do
        Other::TrustCompanyStat.desc(:rating_overall_rank).limit(10).collect(&:company_name)
      end
    end
  end
end
