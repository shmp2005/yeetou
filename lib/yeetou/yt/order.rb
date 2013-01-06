# -*- coding: utf-8 -*-
class Yt::Order
  include Yt::Abstract

  field :user_id, type: Integer
  field :order_number, type: String # 订单编号
  field :seq_number, type: Integer  # 订单序号
  field :price, type: Float         # 订单价格
  field :product_id, type: String   # 产品id
  field :tz_amount, type: Float     # 投资金额，单位元
  field :tz_month, type: Integer    # 投资月数
  field :tz_date, type: Date        # 投资开始日期
  field :good_profit, type: Float   # 乐观收益
  field :normal_profit, type: Float # 一般收益
  field :actual_profit, type: Float # 实际收益

  field :fund_profits, type: Array  # 基金收益率

  field :left_period, type: Integer #低风险剩下的月数
  field :low_tzps, type: Array      #低风险产品，元素 [model, id]
                                                 #10， 新订单，20, 付款订单， 30 试用，99，删除
  field :order_state, type: Integer, default: 10 # 订单状态

  field :region_code, type: Integer              #地区代码
                                                       #1，确认，0，未确认，可以继续修改明细，如储蓄和理财产品
  field :confirmed, type: Boolean, default: false      #订单明细是否确认
  field :pop_pick_dialog, type: Boolean, default: true # 是否弹出dialog

  field :bill_retries, type: Integer, default: 0       # 尝试付款次数
                                                       #0, 已付
  field :bill_state, type: Integer                     # 付款状态
  field :bill_datetime, type: DateTime                 #付款日期
  field :ip, type: String                              # 交易ip
  field :bill_channel, type: String                    #支付渠道 alipay or 99bill

  field :trade_no, type: String                        #alipay支付交易号码
  field :deal_id, type: String                         #bill99 交易号码

  #支付信息 bill99
  field :pay_type, type: String
  field :pay_result, type: String
  field :bank_id, type: String
  field :bank_deal_id, type: String
  field :deal_time, type: String

  #支付所有参数信息
  field :params_out, type: String
  field :params_out_at, type: DateTime
  field :params_in, type: String
  field :params_in_at, type: DateTime

  belongs_to :product, :class_name => "Yt::Product", :foreign_key => "product_id"
  has_many :order_details, :class_name => "Yt::OrderDetail", :foreign_key => "order_id"
  has_one :order_profit, :class_name => 'Yt::OrderProfit'

  scope :rows, lambda { self.in(order_state: [10, 20, 30]) }
  scope :unpaid, lambda { self.in(order_state: [10, 30]) }
  scope :trial, lambda { where(order_state: 30) }
  scope :paid, lambda { where(order_state: 20) }
  scope :paid_or_trial, lambda { self.in(order_state: [20, 30]) }
  scope :by_user, lambda { |user_id| where(user_id: user_id) }
  scope :created_between, lambda { |s_date, e_date| gte(created_at: s_date).lte(created_at: e_date.to_date.next_day) }

  validates_uniqueness_of :order_number, :seq_number
  validates_presence_of :user_id, :product_id, :tz_amount, :tz_month, :tz_date

  ORDER_STATE = Hash[10, '新订单', 20, '已付款', 30, '试用', 99, '已删除']

  def trial?
    order_state == 30
  end

  def paid?
    order_state == 20
  end

  def unpaid?
    [10, 30].include?(order_state)
  end

  def can_pick_tzp?
    (!self.confirmed) && (tz_date + 15.days) >= Date.today
  end

  def seq_number_text
    seq_number.to_s.rjust(3, '0')
  end

  #订单用户
  def user
    @user ||= begin
      User.find(user_id)
    end
  end

  def good_profit_text
    "#{good_profit} %"
  end

  def normal_profit_text
    "#{normal_profit} %"
  end

  def good_earning
    (tz_amount*good_profit/100.0).round
  end

  def normal_earning
    (tz_amount*normal_profit/100.0).round
  end

  #投资结束日期
  def tz_end_date
    tz_date + tz_month.send(:months)
  end

  def tz_date_range
    "#{tz_date.china_ymd} 至 #{tz_end_date.china_ymd}"
  end

  def tz_quarters
    date     = tz_date + 3.months
    quarters = []
    while date <= tz_end_date
      quarters << date
      date += 3.months
    end
    quarters
  end

  def tz_purchase_date_text
    if @pd.nil?
      @pd = begin
        str    = nil
        detail = order_details.in(tzp_type: %w[Other::FinancialProduct Other::Trust]).first
        if detail && detail.tzp
          tzp = detail.tzp
          str = tzp.send(:issue_start_date)
          str = "#{str.china_ymd}开始"
        end

        str || '可以随时'
      end
    end
    @pd
  end

  def update_out(params_out)
    self.params_out    = params_out
    self.params_out_at = Time.now
    self.save
  end

  def pay_confirm(params, bill_channel)
    self.order_state   = 20
    self.bill_state    = 0
    self.bill_datetime = Time.now
    self.bill_retries  += 1

    if bill_channel.to_sym == :bill99
      self.pay_type    = params[:payType]
      self.pay_result  = params[:payResult]
      self.bank_id     = params[:bankId]
      self.deal_id     = params[:dealId]
      self.bank_deal_id= params[:bankDealId]
      self.deal_time   = params[:dealTime]
    end

    if bill_channel.to_sym == :alipay
      self.trade_no= params[:trade_no]
    end

    self.params_in    = params.to_param
    self.params_in_at = Time.now
    self.bill_channel = bill_channel

    self.save
  end

  #近三个月的收益率
  def latest_3m_risk_profit(today=Date.today)
    prev_date = today - 3.month

    prev_sum = order_details.sum { |e| e.is_risk? ? e.actual_amount(prev_date) : 0 }
    now_sum  = order_details.sum { |e| e.is_risk? ? e.actual_amount(today) : 0 }

    if prev_sum.zero?
      0
    else
      ((now_sum - prev_sum)*100.0/prev_sum).round(2)
    end
  end

  #算出组合的日收益率，保存起来，减少每次的计算量
  def get_profits(by_now=Date.today)
    details = self.order_details
    profit  = self.order_profit || build_order_profit(profits: [], last_date: tz_date)
    profits = profit.profits

    current_date = [by_now, tz_end_date].min

    profits.reject! { |e| e.first.to_date >= profit.last_date }
    (profit.last_date..current_date).each do |date|
      day_profit = details.sum { |e| e.actual_profit(date) * e.tzp_ratio/100.0 }.round(2)
      profits << [date.to_date.ymd, day_profit]
    end
    profit.profits   = profits
    profit.last_date = current_date
    profit.save

    hash= Hash.new
    profits.find_all { |e| e.first.to_date <= by_now }.map { |e|
      hash[e.first] = e.last
    }
    hash
  end

  def region
    region = Other::Region.by_code(self.region_code).first

    if region.nil?
      []
    else
      [region, region.parent]
    end
  end

  #更换低收益,高收益的基金有可能变化
  def reset_low(params)
    r_code   = params[:r_code].to_i
    tzp_id   = params[:tzp_id]||''
    tzp_type = params[:tzp_type]||''

    opts = {r_code: r_code, top: 10}
    tzps = Yt::Product.pick_low(self.tz_amount, self.tz_month, opts)
    lows = Yt::Product.high_low(tzps, opts[:top])

    lows = Yt::Product.tz_sort(self.tz_month, lows)

    item_low = lows.find { |e| e[:model] == tzp_type && e[:id].to_s == tzp_id.to_s }
    raise YeetouException, "无效的 item_low" if item_low.nil?

    items_high = Yt::Product.pick_fund(item_low)

    Yt::Order.save_details(self, item_low, items_high, true)

    self.update_attributes! region_code: r_code.to_i, pop_pick_dialog: false

    #重置order_profit
    self.order_profit.delete if self.order_profit
  end

  #如果原来是lccp，在过期当天，则需要追加新的tzp
  def append_low
    return if (self.left_period||0) < 3

    old_low = order_details.find_all { |e| e.is_fixed? }.first
    opts    = {r_code: region_code, top: 5}
    tzps    = Yt::Product.pick_low(old_low.tzp_amount, self.left_period, opts)
    if tzps.count > 1
      new_low = tzps.first

      if new_low[:model] == 'Other::FinancialProduct'
        self.left_period = new_low[:lp]
      else
        self.left_period = 0
      end
      self.low_tzps << [new_low[:model], Date.today.ymd, new_low[:id]]
      self.save!
    end
  end

  class << self
    #生成新的订单
    #{pid: pid, tz_amt: amt, tz_month: month, tz_date, date, x_ip: ip}
    def build_order(user, params, save_flag)
      try_flag   = params[:tf]||'0' #试用标志
      pid, date  = params[:pid], params[:tz_date].to_date
      amt, month = (params[:tz_amt].to_f*10000).round, params[:tz_month].to_i

      tzps = Yt::Product.pick_low(amt, month, {ip: params[:x_ip]})

      unless tzps.empty?

        hl         = item_low = Yt::Product.high_low(tzps).first
        items_high = Yt::Product.pick_fund(hl)

        items = items_high + [item_low]

        if items.count == 0
          raise YeetouException, "没有找到符合你的投资要求的投资品"
        end

        product = Yt::Product.where(id: pid).first
        raise YeetouException, "无效的易投产品号码#{pid}" if product.nil?

        if save_flag
          user_id = user.user.id

          #mark所有未付款或者试用的临时订单为 “删除”
          Yt::Order.where(user_id: user_id).unpaid.update_all :order_state => 99

          seq_number   = Yt::Order.count + 1
          order_number = Yt::NextNumber.next_order_number(pid)
          order        = Yt::Order.create! user_id:      user_id,
                                           product_id:   product.id,
                                           price:        product.price,
                                           order_number: order_number,
                                           seq_number:   seq_number,
                                           tz_amount:    amt,
                                           tz_month:     month,
                                           tz_date:      date,
                                           region_code:  hl[:r_code],
                                           ip:           params[:x_ip],
                                           order_state:  (try_flag=="0" ? 10 : 30)

          order.save!

          order = save_details(order, item_low, items_high, save_flag)
        end

        #puts "订单创建完毕"
      end

      if save_flag
        order || Yt::Order.new
      else
        order = {tz_amount: amt, tz_month: month}
        rtn   = save_details(order, item_low, items_high, save_flag)

        gp, np = (rtn[:good]/100.0).round(2), (rtn[:normal]/100.0).round(2)
        {tz_amount:    amt, tz_month: month, tz_date: date, tz_end_date: (date + month.send(:months)),
         good_profit:  gp, normal_profit: np, pid: pid,
         good_earning: (amt*gp/100.0).round, normal_earning: (amt*np/100.0).round
        }
      end
    end

    #保存订单明细
    def save_details(order, item_low, items_high, save_flag)
      if save_flag
        month = order.tz_month
        amt   = order.tz_amount
      else
        month = order[:tz_month]
        amt   = order[:tz_amount]
      end

      fc = Yt::ProfitPredict.latest_fund_profits(month)

      good, normal             = 0, 0
      sum_ratio                = 0.0
      temp_details, temp_index = [], 1

      #高风险，基金
      items_high.each do |item|
        ratio     = (item[:amt]*100.0/amt).round(2)
        sum_ratio += ratio

        #赚的钱的单位为元
        ph, pn    = fc[2], fc[1]
        earnings  = fc.map { |e| (e/100.0*item[:amt]).round }
        good      += (ph*ratio).round(3)
        normal    += (pn*ratio).round(3)

        temp_details << {
            user_id:      save_flag ? order.user_id : -1,
            order_id:     save_flag ? order.id : 999,
            tzp_id:       item[:id],
            tzp_type:     item[:model],
            tzp_amount:   item[:amt],
            tzp_ratio:    ratio,
            tzp_profits:  fc,
            tzp_earnings: earnings,
            memo:         "",
            t_index:      temp_index
        }
        temp_index += 1
      end

      confirmed_flag = false

      #低风险: 信托，储蓄或理财产品
      ratio          = (100 - sum_ratio).round(2)

      #赚的钱的单位为元
      ep             = item_low[:ks]

      confirmed_flag = true if item_low[:model]=="Other::Trust"
      earnings = [(item_low[:low]*ep/100.0).round]
      good     += (ep*ratio).round(3)
      normal   += (ep*ratio).round(3)

      temp_details << {
          user_id:      save_flag ? order.user_id : -1,
          order_id:     save_flag ? order.id : 999,
          tzp_id:       item_low[:id],
          tzp_type:     item_low[:model],
          tzp_amount:   item_low[:low],
          tzp_ratio:    ratio,
          tzp_profits:  [ep],
          tzp_earnings: earnings,
          memo:         item_low[:memo] ||'',
          t_index:      0
      }

      if save_flag
        order.order_details.delete_all

        temp_details.sort_by { |e| e[:t_index] }.each do |t|
          Yt::OrderDetail.create! user_id:      t[:user_id],
                                  order_id:     t[:order_id],
                                  tzp_id:       t[:tzp_id],
                                  tzp_type:     t[:tzp_type],
                                  tzp_amount:   t[:tzp_amount],
                                  tzp_ratio:    t[:tzp_ratio],
                                  sequence:     t[:t_index],
                                  tzp_profits:  t[:tzp_profits],
                                  tzp_earnings: t[:tzp_earnings],
                                  memo:         t[:memo]
        end

        #计算乐观和中观收益率
        order.good_profit     = (good/100.0).round(2)
        order.normal_profit   = (normal/100.0).round(2)
        order.fund_profits    = fc
        order.confirmed       = confirmed_flag
        order.pop_pick_dialog = true

        if item_low[:model] == 'Other::FinancialProduct'
          order.left_period = item_low[:lp]
        else
          order.left_period = 0
        end
        order.low_tzps = [[item_low[:model], Date.today.ymd, item_low[:id]]]

        order.save!
      end
      save_flag ? order : {good: good, normal: normal}
    end

    #订单付款确认
    def pay_order(params, bill_channel)
      case bill_channel
        when :bill99 then
          pay_order_bill99(params)
        when :alipay then
          pay_order_alipay(params)
      end
    end

    def pay_order_bill99(params)
      response = KuaiQian::Response.new(params)
      order_id = params[:orderId]

      order = Yt::Order.where(order_number: order_id).first

      if response.successful?
        if order
          if order.bill_state == 0
            {code: -2, msg: "重复提交付款"}
          else
            order.pay_confirm(params, :bill99)
            {code: 0, msg: "付款成功"}
          end
        else
          {code: -1, msg: "无效的订单号码"}
        end
      else
        if order
          order.inc :bill_retries, 1
        end
        {code: 99, msg: "errCode: #{params[:errCode]}。付款失败，系统再次验证中。。。"}
      end
    end

    #接收支付宝的付款结果通知
    def pay_order_alipay(params)
      log "params:  #{params.to_param}"
      response     = AliPay::Response.new(params)
      order_number = response.order_number

      log "order_number=#{order_number}"

      order = Yt::Order.where(order_number: order_number).first

      if response.successful?
        if order
          if order.bill_state == 0
            {code: -2, msg: "重复提交付款"}
          else
            order.pay_confirm(params, :alipay)
            {code: 0, msg: "付款成功"}
          end
        else
          {code: -1, msg: "无效的订单号码"}
        end
      else
        if order
          order.inc :bill_retries, 1
        end
        {code: 99, msg: "errCode: #{params[:errCode]}。付款失败，系统再次验证中。。。"}
      end
    end

    #用于迁移旧的订单数据
    def fix_old_data(order_number = nil)
      if order_number.nil?
        #orders = Yt::Order.all
        orders = Yt::Order.in(left_period: [nil])
      else
        #orders = Yt::Order.in(left_period: [nil]).where(order_number: order_number)
        orders = Yt::Order.where(order_number: order_number)
      end
      puts "Total old orders #{orders.count}"

      orders.each do |order|
        lp        = 0
        tzp_array = []
        order.order_details.each do |d|
          if d.is_fixed?
            d.sequence = 0
            lp         = case d.tzp_type
                           when "Other::Trust" then
                             order.tz_month - d.tzp.period.send(:months)
                           when "Other::FinancialProduct" then
                             order.tz_month - (d.tzp.period/30.0).round
                           else #Other::Saving
                             0
                         end


            tzp_array = [d.tzp_type, d.created_at.to_date.ymd, d.tzp_id]
          else
            d.sequence = 1
          end
          d.save
        end

        order.left_period     = [lp, 0].max
        order.low_tzps        = [tzp_array]
        order.confirmed       = false
        order.pop_pick_dialog = false
        order.save!
      end
      puts "Fix old order & order details successfully"
    end
  end
end
