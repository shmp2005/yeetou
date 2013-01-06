# -*- coding: utf-8 -*-
module ToProduct
  extend ActiveSupport::Concern

  included do

  end

  module ClassMethods
    #存期代码和月数
    CODE_MONTHS  = Hash['211', 3, '212', 6, '213', 12, '214', 24, '215', 36, '216', 60]
    HASH_PERIODS = Hash[36, '3年期', 24, '2年期', 12, '1年期', 6, '半年', 3, '3个月']

    #month, user inputs a month
    #tzps is an array, each element is a hash like
    # [{period: m, profit: r}]
    # return an array, element as below
    # [{period: m, profit: r, k: k, memo: memo}]
    def tz_sort(month, tzps=[])

      china_fixed_rates = bank_fixed_rates

      tzps.map! do |e|
        p             = month - e[:period]
        extra_periods = saving_periods(p)
        extra_profit  = extra_saving_profit(extra_periods, china_fixed_rates)
        e[:k]         = ((e[:profit]*e[:period] + extra_profit*12).to_f/month).round(3)
        e[:ks]        = (e[:k]/12.0*month).round(3)

        if e[:model].to_s == 'Other::Saving'
          sp       = saving_periods(month)
          e[:memo] = sp.map { |ex| HASH_PERIODS[ex.to_i] }.join("+")
        else
          e[:memo] = extra_periods.join("+")
        end
        e[:kx] = extra_profit
        e[:lp] = p
        e
      end
      tzps.sort_by { |e| e[:k] }.reverse
    end

    #bank_rates: {211: 2.2, 213: 2.8]}
    def extra_saving_profit(periods, bank_rates={ })
      if bank_rates.empty?
        fixed_rates = bank_fixed_rates
      else
        fixed_rates = bank_rates
      end

      periods.sum { |m|
        code = CODE_MONTHS.find { |c| c.last== m }.first.to_sym
        (fixed_rates[code]||0.0)/12.0*m
      }
    end

    def bank_fixed_rates(bank_id='0')
      hash = Hash.new
      Other::Interest.query_rates(bank_id).in(product_code: CODE_MONTHS.keys).map { |e| hash[e.product_code.to_sym] = e.rate }
      hash
    end

    #输入一个月份，得到一个存期列表
    def saving_periods(month)
      fixed = CODE_MONTHS.values
      mm    = []

      k  = -1
      cm = month
      c  = 0
      begin
        xx = fixed.map { |e| cm - e }
        x  = xx.reject { |e| e < 0 }.sort.first

        if x.present?
          k = xx.index(x)
          if k
            y = fixed[k]
            mm << y
            cm -= y
          end
        end
        c +=1
      end until x.nil? || k.nil? || c > 10

      mm
    end

    #calling sequence,
    #   tzps = pick_low(amt, month, opts)
    #   hl = high_low(tzps)
    #   highs = pick_fund(hl)


    #tz_amt 单位元，tz_month, 单位月
    #opts, {top: top, ip: ip, r_code: r_code, b_ids: b_ids}
    def pick_low(tz_amt, tz_month, opts={ })
      min_amt = min_tz_amt(tz_amt, tz_month)

      r_code = opts[:r_code]
      unless r_code.nil?
        region = region_by_ip(opts[:ip])
        r_code = region.code if region
      end

      trusts  = pick_trust(min_amt, tz_month)
      lccps   = pick_lccp(min_amt, tz_month, r_code, opts[:b_ids])
      savings = pick_saving(tz_month, r_code, opts[:b_ids])

      #puts "trusts=>#{trusts.count}"
      #puts "lccps=>#{lccps.count}"
      #puts "savings=>#{savings.count}"

      tzps    = (trusts + lccps + savings).flatten.map { |e|
        e.merge({ tz_amt: tz_amt, tz_month: tz_month, r_code: r_code })
      }

      top = opts[:top] || 5
      tz_sort(tz_month, tzps)[0, top]
    end

    def high_low(tzps, top=1)
      raise YeetouException, "没有投资品，请先调用 pick_low " if tzps.nil? or tzps.empty?

      z = bad_profit(tzps.first[:tz_month])
      tzps.map { |tzp|
        s0 = (tzp[:tz_amt].to_f/(tzp[:k] + z)*z).round

        if tzp[:min_amt] < s0
          ss = s0.to_f
        else
          ss = tzp[:min_amt].to_f
        end

        if tzp[:model] =='Other::Trust'
          low = (ss.to_f/10000).round*10000
        else
          low = (ss.to_f/1000).round*1000
        end
        high = (tzp[:tz_amt] - low).round
        tzp.merge({ low: low, high: high })
      }[0, top]
    end

    #获取高风险产品，即基金
    def pick_fund(hl)
      high = hl[:high]

      raise "高风险产品金额错误(#{high})" if high <= 0.0

      case (high.to_f/10000.0).round(2)
        when (0...10) then
          fund = Fund::FundPool.f01.asc(:seq_number).first
          if fund.nil?
            []
          else
            [{ id: fund.symbol, ptype: :f01, model: "Fund::Fund", amt: high }]
          end
        else
          #when (10...9999999) then
          temp = []
          Fund::FundPool.f01.asc(:seq_number).limit(2).map { |f|
            temp << { id: f.symbol, ptype: :f01, model: "Fund::Fund", amt: (high*0.5).round(2) }
          }
          temp
      end
    end

    alias_method :pick_high, :pick_fund

    #tz_amt 单位元，tz_month, 单位月
    def min_tz_amt(tz_amt, tz_month)
      y = bank_fixed_rates['213'.to_sym]||0.0

      z = bad_profit(tz_month)
      (tz_amt.to_f/(y+z)*z).round
    end

    def bad_profit(tz_month)
      pp = Yt::ProfitPredict.latest
      bp = pp.send("m#{tz_month.to_i}")[2].abs*12.0/tz_month
      bp.round(3)
    end

    #min_amt, 单位元, tz_month, 单位月
    def pick_trust(min_amt, tz_month)
      trusts  = Other::Trust.by_initial_amount(0.1, (min_amt/10000.0).round(2))
      trusts  = trusts.gt0_expected_profit.pre_on_sales
      results = []
      trusts.each do |d|
        if d.period <= tz_month

          initial_amount = (d.initial_amount*10000).round
          results << {
              model:  'Other::Trust', id: d.id, name: d.name,
              profit: d.expected_profit, period: d.period, min_amt: initial_amount
          }
        end
      end
      results
    end

    #min_amt, 单位元, tz_month, 单位月
    #r_code, region_code, b_ids, bank_ids
    def pick_lccp(min_amt, tz_month, r_code=nil, b_ids = nil)

      lccp        = Other::FinancialProduct.by_period(90, (tz_month*1.025*30).round)
      lccp        = lccp.by_initial_amount(1, min_amt).gt0_expected_profit
      lccp_fields = Other::FinancialProduct.fields.keys - %w[risk_desc]
      lccp        = lccp.only(lccp_fields).pre_on_sales

      ids  = Other::LccpPool.all.collect(&:lccp_id)
      lccp = lccp.in(id: ids)

      if b_ids.present?
        bank_names = Other::Bank.in(id: b_ids.split(";")).collect(&:name)
      else
        bank_names = banks_by_region(r_code).collect(&:name)
      end

      if bank_names.present?
        lccp = lccp.in(bank_name: bank_names)
      end

      results = []
      lccp.each do |d|
        p  = (d.period/30.0).round
        ep = d.expected_profit.round(2)

        results << {
            model:  'Other::FinancialProduct', id: d.id, name: d.name,
            profit: ep, period: p, min_amt: d.initial_amount
        }
      end
      results
    end

    #tz_month, 单位月
    #r_code, region_code, b_ids, bank_ids
    def pick_saving(tz_month, r_code=nil, b_ids = nil)
      regular_months = CODE_MONTHS.values.sort
      p              = case
                         when tz_month >= regular_months.max then
                           regular_months.max
                         when tz_month <= regular_months.min then
                           regular_months.min
                         else
                           regular_months.find_all { |e| e <= tz_month }.max
                       end

      savings = Other::Saving.where(period: p)

      if b_ids.present?
        bank_ids = b_ids.split(";")
      else
        bank_ids = banks_by_region(r_code).collect(&:id)
      end
      if bank_ids.present?
        savings = savings.in(bank_id: bank_ids)
      end

      results = []
      savings.each do |d|
        results << {
            model:  'Other::Saving', id: d.id, name: d.name,
            profit: d.rate, period: d.period, min_amt: 0
        }
      end
      results
    end

    #根据ip找城市代码
    def region_by_ip(ip)
      if ip.present?
        ip_table = Yt::IpTable.search_by(ip).first
        if ip_table
          region         = nil
          province, city = ip_table.province, ip_table.city
          if city.present?
            region = Other::Region.by_name(city).first
          end
          if region.nil? && province.present?
            region = Other::Region.by_name(province).first
          end

          if region && region.parent.code == 1
            region = region.children.first
          end
          region
        end
      end
    end

    #根据地区找银行, 对四大直辖市不限制地区
    def banks_by_region(r_code)
      if r_code.present?
        region = Other::Region.by_code(r_code).first
        if region
          if %w[北京市 上海市 天津市 重庆市].include?(region.parent.name)
            r_codes = region.parent.children.collect(&:code)
          else
            r_codes = [r_code]
          end
          bank_ids = Other::Outlet.in(region_code: r_codes).collect(&:bank_id).uniq
          Other::Bank.in(id: bank_ids)
        else
          []
        end
      else
        []
      end
    end
  end
end
