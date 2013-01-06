# -*- coding: utf-8 -*-
class Other::TzSetting
  class << self
    def tzp_sort_lccp(opts={ })

      model = opts[:model]
      return [] if model.present? && model != 'lccp'

      fields = Other::FinancialProduct.fields.keys - [:risk_desc]
      tzps   = []
      today  = Date.today

      newest = Other::FinancialProduct.pre_on_sales.gt0_expected_profit.desc(:created_at, :grab_batch).first

      Other::FinancialProduct.pre_on_sales.gt0_expected_profit.only(fields).each do |d|

        tag_ids = opts[:ids]
        if tag_ids.present?
          next unless tag_ids.include?(d.id)
        end

        if d.is_pre_sale?
          days   = d.issue_start_date.diff_days(today)
          rating = period_pre_sales[days]||0
        else
          total_days = d.issue_start_date.diff_days(d.issue_end_date)
          if total_days > 0
            r      = today.diff_days(d.issue_start_date)*1.0/total_days
            pk     = period_sell_lccp.keys.find { |k| r>k.first && r<= k.last }
            rating = period_sell_lccp[pk||'']||0
          end
        end

        rating ||= 0

        ep  = d.expected_profit || 0
        key = profit_lccp.keys.find { |k| ep > k.first && ep <= k.last }
        if key
          rating += profit_lccp[key]||0
        end

        rating += adjust_lccp[:bb] if d.breakeven_flag
        rating += adjust_lccp[:fixed] if d.profit_type =~ /固定收益/
        bank = Other::Bank.by_alias_names(d.bank_name).first
        rating += adjust_lccp[:nation] if bank && bank.nation_wide?

        if newest.created_at.to_date.ymd == d.created_at.to_date.ymd &&
            newest.grab_batch == d.grab_batch
          rating += adjust_lccp[:new]
        end

        tzps << { model: d.class.name, rating: rating||0, id: d.id, name: d.name,
                  bb:    d.breakeven_flag||'', pt: d.profit_type,
                  bank:  d.bank_name, period: ((d.period||0)/30.0).round,
                  amt:   ((d.initial_amount||0)/10000.0).round,
                  batch: d.grab_batch, created_at: d.created_at.localtime.to_date.ymd }
      end

      to_file(tzps, :lccp) if opts[:file]

      tzps.sort_by { |e| e[:rating] }.reverse
    end

    def tzp_sort_trust(opts ={ })
      model = opts[:model]
      return [] if model.present? && model != 'trust'

      tzps  = []
      today = Date.today

      Other::Trust.pre_on_sales.gt0_expected_profit.each do |d|

        tag_ids = opts[:ids]
        if tag_ids.present?
          next unless tag_ids.include?(d.id)
        end

        if d.issue_start_date > today
          rating = 40
        else
          r      = d.issue_start_date.diff_days(today)
          rating = period_sell_trust[r]||0
        end

        ep  = d.expected_profit || 0
        key = profit_trust.keys.find { |k| ep > k.first && ep <= k.last }
        if key
          rating += profit_trust[key]||0
        end

        amt = d.initial_amount||0
        key = initial_amt_trust.keys.find { |k| amt >= k.first && amt < k.last }
        if key
          rating += initial_amt_trust[key]||0
        end
        rating += adjust_trust[:base] if d.invest_target == '基础设施'
        rating += adjust_trust[:listed] if d.invest_target == '上市公司'
        rating += eval("#{d.mortgage_ratio}#{adjust_trust[:mortgage]}").round(1) if d.mortgage_ratio

        tzps << { model:         d.class.name, rating: rating||0, id: d.id,
                  name:          d.name, profit: d.expected_profit, period: d.period,
                  issue_start_date:    d.issue_start_date.ymd, amt: d.initial_amount,
                  invest_target: d.invest_target, mortgage_ratio: d.mortgage_ratio||0
        }
      end
      to_file(tzps, :trust) if opts[:file]

      tzps.sort_by { |e| e[:rating] }.reverse
    end

    def tzp_sort_saving(opts={ })
      model = opts[:model]
      return [] if model.present? && model != 'saving'

      b212  = Other::Saving.where(product_code: 212).where(delta_ratio: 10).collect(&:bank_id).uniq
      b213  = Other::Saving.where(product_code: 213).where(delta_ratio: 10).collect(&:bank_id).uniq
      bids  = b212 & b213
      names = Other::Bank.nation_wide.in(id: bids).collect(&:name).sort[0, 6].map { |e| "[#{e}]" }

      [{ model: "Other::Saving", id: Other::Saving.last.id, bank_names: names }]
    end

    def tzp_sort_bond(opts={ })
      model = opts[:model]
      return [] if model.present? && model != 'bond'

      tzps = []
      Other::Bond.onsell_bonds.map { |b|

        tag_ids = opts[:ids]
        if tag_ids.present?
          next unless tag_ids.include?(b.id)
        end

        tzps << { model: b.class.name, id: b.id, name: b.name }
      }
      tzps
    end

    def period_pre_sales
      Hash[1, 35, 2, 30, 3, 20]
    end

    def period_sell_trust
      h = Hash.new
      (0..35).map { |e| h[e]= 35 - e }
      h
    end

    def period_sell_lccp
      Hash[[0, 0], 35, [0, 0.2], 33, [0.2, 0.33], 30, [0.33, 0.5], 20,
           [0.5, 0.67], 12, [0.67, 0.8], 6, [0.8, 1], 0]
    end

    def profit_trust
      Hash[[6.5, 7.0], 3, [7.0, 7.5], 3, [7.5, 8.0], 5, [8.0, 8.5], 8,
           [8.5, 9.0], 10, [9.0, 9.5], 13, [9.5, 10.0], 15, [10.0, 10.5], 18,
           [10.5, 11.0], 20, [11.0, 11.5], 25, [11.5, 12.0], 30, [12.0, 12.5], 30,
           [12.5, 13.0], 25, [13.0, 25.0], 20]
    end

    def profit_lccp
      Hash[[3, 3.5], 3.3, [3.5, 4.0], 6.7, [4.0, 4.3], 10, [4.3, 4.6], 14.7,
           [4.6, 4.9], 16.7, [4.9, 5.2], 19.3, [5.2, 5.5], 20, [5.5, 5.8], 20,
           [5.8, 6.1], 19.3, [6.1, 6.4], 13.3, [6.4, 6.7], 6.7, [6.7, 7.0], 6.7,
           [7.0, 10.0], 6.7]
    end

    def initial_amt_trust
      Hash[[0.1, 100], 5, [100, 300], 3, [300, 500], -5.0, [500, 999999999], -10]
    end

    def adjust_lccp
      Hash[:bb, 3, :fixed, 3, :nation, 4, :new, 5]
    end

    def adjust_trust
      Hash[:base, 5, :listed, 4, :mortgage, "*10.0/100.0"]
    end

    def tzp_counts
      Rails.cache.fetch('tzp_count', :expires_in => 1.hour) {
        saving_count = Other::Saving.count
        trust_count  = Other::Trust.pre_on_sales.count
        lccp_count   = Other::FinancialProduct.pre_on_sales.count
        bond_count   = Other::Bond.onsell_bonds.count
        {saving: saving_count, trust: trust_count,
         lccp:   lccp_count, bond: bond_count
        }
      }
    end

    private
    def to_file(tzps, file_name)

      if tzps.empty?
        puts "tzps is empty"
        return
      end

      file=Rails.root.to_s + "/public/tzp_setting_#{file_name}.txt"
      File.open(file, "a") do |f|
        f.puts ""

        f.puts tzps.first.keys.join(",")
        tzps.map { |e|
          f.puts e.values.join(",")
        }
      end
      puts "dump to #{file}"
    end
  end
end
