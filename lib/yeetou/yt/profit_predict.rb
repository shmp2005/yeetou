# -*- coding: utf-8 -*-
class Yt::ProfitPredict
  include Yt::Abstract

  #制订的月份 201211
  field :month, type: String
  #当前的大盘点位
  field :point, type: Integer
  #[month，point, bad, normal, good]
  #[月份，点位，悲观，中观，乐观]
  (3..36).each do |month|
    field "m#{month}".to_sym, type: Array
  end
  field :y1_fixed, type: Float
  field :lccp, type: Float
  field :trust, type: Float
  field :last_rolled_at, type: DateTime

  #0 发布, 10 新录入
  field :state, type: Integer

  class << self

    def latest_fund_profits(month)
      latest.send("m#{month}")[2, 3]
    end

    #最新的预测数据
    def latest
      where(state: 0).desc(:month, 1).first
    end

    #daily 在售预售平均收益率
    def calc_lccp_trust
      my    = latest
      lccp  = Other::FinancialProduct.pre_on_sales.gt0_expected_profit.avg(:expected_profit)
      trust = Other::Trust.pre_on_sales.gt0_expected_profit.avg(:expected_profit)
      my.update_attributes! lccp: lccp.round(2), trust: trust.round(2), last_rolled_at: Time.now
    end

    #导入数据从文件 public/system/profit_predict/yyyymm.txt
    def import(year_month)
      unless year_month =~ /\d{6}/
        raise YeetouException, "无效的year_month(#{year_month}). 格式应该为yyyymm"
      end

      date = "#{year_month}01".to_date
      pp   = self.find_or_create_by(month: year_month)

      file=Rails.root.to_s + "/public/system/profit_predict/#{year_month}.txt"
      File.readlines(file).each_with_index do |line, index|
        array = line.gsub("\r\n", "").split(";")
        if array.length == 4
          if index == 0
            pp.point    = array[0]
            pp.y1_fixed = array[1]
            pp.lccp     = array[2]
            pp.trust    = array[3]
          else
            p_array = [date.next_month(2 + index - 1).end_of_month,
                       array[1].to_i, array[0].to_f, array[2].to_f, array[3].to_f]
            pp.send "m#{index + 2}=", p_array
          end
        end
      end
      pp.state = 0
      pp.save!

      calc_lccp_trust

      log("==Import #{year_month} profit predict successfully.")
    end
  end
end
