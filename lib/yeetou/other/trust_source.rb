# -*- coding: utf-8 -*-
class Other::TrustSource
  include Other::Abstract
  include Mongoid::Timestamps

  field :trust_company_id, type: String    #信托公司
  field :name, type: String                #产品名称
  field :issue_start_date, type: Date      #发行开始日期
  field :period, type: Integer             #产品期限
  field :expected_profit, type: Float      #预期年收益率
  field :initial_amount, type: Integer     #门槛金额,万
  field :invest_target, type: String       #投资目标

  field :sell_state, type: Integer         #销售状态 # 0，预约，10 在售，20 售罄，30 运行，99 结束
  field :issue_end_date, type: Date        #发行结束日期
  field :profit_type, type: String         #收益类型
  field :trust_type, type: String          #产品类型
  field :issue_scale, type: String         #发行规模
  field :invest_method, type: String       #投资方式
  field :yeetou_risk_control, type: String #易投风险控制
  field :related_info, type: String        #相关信息
  field :capital_usage, type: String       #资金使用情况
  field :issue_region, type: String        #发行地区

                                        #Other fields
  field :project_manager, type: String  #项目经理
  field :currency, type: String         #理财币种
  field :management_type, type: String  #投资管理类型
  field :sell_target, type: String      #发售对象
  field :period_type, type: String      #期限类型
  field :actual_profit, type: Float     #实际收益率
  field :trust_fee_rate, type: Float    #资金托管费率
  field :sell_fee_rate, type: Float     #销售手续费率
  field :establish_date, type: Date     #成立日期
  field :establish_scale, type: Integer #成立规模
  field :breakeven_flag, type: Boolean  #是否保本
  field :due_date, type: Date           #到期日期
  field :yeetou_rating, type: String    #易投评价
  field :mortgage_ratio, type: Float    #抵押率
  field :credit_info, type: String      #信用增级


  #数据状态  0:可发布 10：数据缺失 20：数据异常 100:待抓取 99:抓取错误
                                      # 30:待核准, 40:强制发布
  field :state, type: Integer
  field :multiple_flag, type: Boolean #是否有多个
  field :url, type: String            #抓取的URL

  #set a default url as url has a unique index
  before_save :set_object_url

  index({ url: 1 }, { unique: true, name: "url_index" })
  index({ state: 1 }, { name: "state_index" })

  belongs_to :trust_company, :class_name => 'Other::TrustCompany'
  scope :latest_publishes, lambda { |date=Date.today| where(state: 0).gte(updated_at: date) }
  scope :latest_forces, lambda { |date=Date.today| where(state: 40).gte(updated_at: date) }

  SELL_STATE = [['预约', 0], ['在售', 10], ['售罄', 20], ['运行', 30], ['结束', 99]]
  STATE      = [['待抓取', 100], ['抓取错误', 99], ['数据缺失', 10],
                ['数据异常', 20], ['可发布', 0], ['待核准', 30], ['强制更新', 40]]

  def can_dup?
    multiple_flag
  end

  def check_state(save_flag=false)
    #数据缺失
    if self.name.blank? or (self.expected_profit||0).zero? or self.trust_company_id.blank? or
        self.issue_start_date.nil? or (self.period||0).zero? or (self.initial_amount||0).zero? or
        self.invest_target.blank?
      s_state = 10
    else
      # 数据异常
      if self.expected_profit > 25 or self.initial_amount > 10000
        s_state = 20
      else
        #数据发布
        s_state = 0
      end
    end
    self.update_attribute :state, s_state if save_flag

    s_state
  end

  class << self

    #roll到基础库
    def roll(from_date=Date.today)
      log("====Begin rolling trusts====")
      _internal_roll(Other::TrustSource.latest_publishes(from_date), false)
      log("====End rolling trusts====")
    end

    def roll_force_update(from_date=Date.today)
      log("====Begin rolling force update trusts====")
      _internal_roll(Other::TrustSource.latest_forces(from_date), true)
      log("====End rolling force update trusts====")
    end

    def grab_latest
      #抓前2页足够了
      grab_link('在售', 1)
      grab_link('开放期', 1)

      grab_detail
    end

    #state: 在售，开放期
    #see http://www.yanglee.com/NodePage.aspx?NodeID=63
    def grab_link(state, from_page=nil)
      log("================grab links================")
      new_trusts = 0
      mp         = from_page || max_page
      log("=====state: #{state}, max_page: #{mp}===")

      mp.downto(1) do |page|
        begin
          doc = get_list_doc(page, state)
          trs = doc.css("#home .s_class ul li h3 a")
          trs.length.downto(1) do |index|
            link    = trs[index - 1]
            this_url="#{base_url}#{link.attributes["href"].text}"
            trust   = Other::TrustSource.where(:url => this_url).first

            if trust.nil?
              Other::TrustSource.create! url: this_url, :name => link.attributes["title"].text, :state => 100

              new_trusts += 1
            end
          end
        rescue => e
          log(e.message)
        end
      end
      log("=====Total #{new_trusts}==Done!================")
    end

    def grab_detail(state=100)
      log("============grab detail==============")
      Other::TrustSource.where(:state => state).limit(2000).each_with_index do |t, index|
        begin
          log("detail #{index + 1}")
          tds = get_doc(t.url).css("table.cpk_XX td:not([class])")

          company = Other::TrustCompany.find_or_create_by(:name => tds[1].text)

          t.trust_company_id=company.id
          t.project_manager = tds[2].text
          t.trust_type      = tds[3].text
          t.trust_type="集合信托" unless t.trust_type.present?

          t.sell_state      = tds[4].text == '在售' ? 10 : nil
          t.currency        = tds[5].text
          t.management_type = tds[6].text

          issue_dates        = tds[7].text.split("至")
          t.issue_start_date = to_date(issue_dates.first)
          t.issue_end_date   = to_date(issue_dates.last)

          t.sell_target    = tds[8].text
          t.issue_scale    = tds[9].text
          t.initial_amount = to_number(tds[10].text)

          periods         = tds[11].text.split("至")
          p               = periods.first
          p               = p.present? ? p : periods.last
          t.period        = to_number(p)
          t.multiple_flag = periods.all? { |e| e.present? }
          t.period_type   = tds[12].text

          profits           = tds[13].text.split("至")
          p                 = profits.first
          p                 = p.present? ? p : profits.last
          t.expected_profit = to_number(p)
          #再次判断是否有多个收益率
          t.multiple_flag = profits.all? { |e| e.present? } unless t.multiple_flag

          pts           = tds[14]
          t.profit_type = c_str(pts.children.first.text)
          t.profit_type = "固定型" unless t.profit_type.present?
          t.breakeven_flag = to_boolean(c_str(pts.children.last.text))

          t.invest_method   = tds[15].text
          t.invest_target   = tds[16].text
          t.trust_fee_rate  = to_number(tds[17].text)
          t.sell_fee_rate   = to_number(tds[18].text)
          t.establish_date  = to_date(tds[19].text)
          t.establish_scale = to_number(tds[20].text)
          t.due_date        = to_date(tds[21].text)
          t.actual_profit   = to_number(tds[22].text)
          t.issue_region    = tds[23].text
          t.capital_usage   = tds[24].text
          t.credit_info     = tds[25].text
          t.related_info    = tds[26].inner_html
          t.save

          t.check_state(true)

        rescue => e
          t.update_attributes :state => 99
          log(e.message)
        end
      end
      log("========Grab trust's detail Done!==============")
    end

    def max_page(state='在售')
      doc   = get_list_doc(1, state)
      pager = doc.css("#Page td b")
      pager.nil? ? 1 : (pager.text.to_i/60.0).ceil
    end

    def get_list_doc(page=1, state='在售')
      url = "#{base_url}/NodeHot.aspx?NodeID=6&Type=集合&ProductState=#{state}&jigou=&qixian=0|3650&shouyi=0|100&InvestField=&ApplyWay=&submit1.x=31&submit1.y=34&p=#{page}"
      get_doc(url)
    end

    def base_url
      "http://www.yanglee.com"
    end

    def red_fields
      %w[trust_company_id issue_start_date period
                    expected_profit initial_amount invest_target]
    end

    def orange_fields
      %w[sell_state issue_end_date profit_type trust_type
                    issue_scale invest_method yeetou_risk_control related_info
                    capital_usage issue_region]
    end

    def _internal_roll(source_objects, force_flag=false)
      source_objects.each do |ts|
        state = ts.check_state(true)
        unless state.zero?
          log("关键栏位数据缺失。ts.id=#{ts.id}")
          next
        end

        opts = Hash.new
        red_fields.map { |f| opts[f.to_sym] = ts.send(f.to_sym) }
        t = Other::Trust.where(opts).first
        if t.present?
          #强制更新
          if force_flag
            orange_fields.map { |f|
              val_src = ts.send f.to_sym
              t.send "#{f}=", val_src
            }
            t.save

            #orange fields有不同，变为可发布
            ts.update_attributes state: 0
          else
            #正常roll
            diff_flag = orange_fields.map { |f|
              val_dest = t.send f.to_sym
              val_src  = ts.send f.to_sym
              t.send "#{f}=", val_src if val_dest.blank?

              if val_src.present? && val_dest.present?
                val_src != val_dest
              else
                false
              end

            }.any? { |e| e }
            t.save

            #orange fields有不同，变为待核准
            ts.update_attributes state: 30 if diff_flag
          end
        else
          t = Other::Trust.new
          ts.fields.keys.reject { |k| %w[_id _type].include?(k) }.each do |f|
            val = ts.send(f.to_sym)
            t.send "#{f}=", val if t.fields.keys.include?(f)
          end
          t.save
        end
      end
    end

    #用于迁移就数据
    def fix_old_data
      trusts = Other::Trust.all
      log("Begin to fix old trust data (#{trusts.count})")
      trusts.each_with_index do |t, index|
        log(index)
        t.issue_start_date = t.issue_date.nil? ? '1900-01-01' : t.issue_date
        t.issue_end_date   = t.issue_date.nil? ? '1900-01-01' : t.issue_date + 1.month
        period             = (t.min_period||0).zero? ? t.max_period : t.min_period
        t.period           = period
        t.initial_amount   = t.threshold_amount
        t.save
      end
      log("Fix old trust data successfully")
    end


    def unset_old_fields(confirm=false)
      old_fields = %w[amount_unit issue_date max_period min_period partner_name
          partner_type period_unit  threshold_amount  max_expected_profit]
      if confirm
        old_fields.map { |fld| Other::Trust.all.unset fld.to_sym }
        log("===Old fields: #{old_fields.join(",")} unset successfully")
      end
    end
  end
end
