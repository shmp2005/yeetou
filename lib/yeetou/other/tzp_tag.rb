# -*- coding: utf-8 -*-
class Other::TzpTag
  include Other::Abstract
  include Mongoid::Timestamps

  #fields & index
  begin
    #符号
    field :symbol, type: String
    #tag名称
    field :name, type: String
    #说明
    field :description, type: String
    #所属类别
    field :category, type: String
    #符合的投资品数
    field :matches, type: Integer, default: 0
    #查询数
    field :searches, type: Integer, default: 0

    index({category: 1}, {name: "category_index"})
    index({name: 1}, {name: "name_index"})
  end

  scope :by_symbol, lambda { |symbol| where(symbol: symbol) }

  class << self
    def cached_tags
      #memkey = "Other::TzpTag.cached_tags"
      #Rails.cache.fetch(memkey, :expires_in => 30.minutes) do
      Other::TzpTag.gt(matches: 0).desc(:matches)
      #end
    end

    #all symbol methods
    begin
      def all_lccp
        ids = Other::FinancialProduct.pre_on_sales.only(:id).collect(&:id)
        {model: 'lccp', ids: ids}
      end

      def all_trust
        ids = Other::Trust.pre_on_sales.only(:id).collect(&:id)
        {model: 'trust', ids: ids}
      end

      def all_bond
        ids = Other::Bond.onsell_bonds.only(:id).collect(&:id)
        {model: 'bond', ids: ids}
      end

      def bb_lccp
        ids = Other::FinancialProduct.pre_on_sales.only(:id).by_breakeven(true).collect(&:id)
        {model: 'lccp', ids: ids}
      end

      def y1_trust
        ids = Other::Trust.pre_on_sales.only(:id).where(period: 12).collect(&:id)
        {model: 'trust', ids: ids}
      end

      def w100_trust
        ids = Other::Trust.pre_on_sales.only(:id).where(initial_amount: 100).collect(&:id)
        {model: 'trust', ids: ids}
      end

      def base_trust
        ids = Other::Trust.pre_on_sales.only(:id).where(invest_target: '基础设施').collect(&:id)
        {model: 'trust', ids: ids}
      end

      def big_bank_lccp
        bank_names = %w[中国银行 建设银行 农业银行 工商银行 交通银行 招商银行 邮政储蓄]
        ids        = Other::FinancialProduct.pre_on_sales.only(:id).in(bank_name: bank_names).collect(&:id)
        {model: 'lccp', ids: ids}
      end

      def high_rate_saving
        ids = Other::Saving.where(product_code: 213, delta_ratio: 10).collect(&:id)
        {model: 'saving', ids: ids}
      end

      def gt5_lccp
        ids = Other::FinancialProduct.pre_on_sales.only(:id).gt(expected_profit: 5.0).collect(&:id)
        {model: 'lccp', ids: ids}
      end

      def gt10_trust
        ids = Other::Trust.pre_on_sales.only(:id).gt(expected_profit: 10.0).collect(&:id)
        {model: 'trust', ids: ids}
      end

      def top10_trust
        c_names = Other::TrustCompanyStat.lte(rating_overall_rank: 10).collect(&:company_name)
        c_ids   = Other::TrustCompany.in(name: c_names).collect(&:id)
        ids     = Other::Trust.pre_on_sales.only(:id).in(trust_company_id: c_ids).collect(&:id)
        {model: 'trust', ids: ids}
      end

      def y2_trust
        ids = Other::Trust.pre_on_sales.only(:id).where(period: 24).collect(&:id)
        {model: 'trust', ids: ids}
      end

      def w300_trust
        ids = Other::Trust.pre_on_sales.only(:id).where(initial_amount: 300).collect(&:id)
        {model: 'trust', ids: ids}
      end

      def lt100w_trust
        ids = Other::Trust.pre_on_sales.only(:id).lt(initial_amount: 100).collect(&:id)
        {model: 'trust', ids: ids}
      end

      def m3_lccp
        ids = Other::FinancialProduct.pre_on_sales.only(:id).lt(period: 93).collect(&:id)
        {model: 'lccp', ids: ids}
      end

      def w5_lccp
        ids = Other::FinancialProduct.pre_on_sales.only(:id).where(initial_amount: 50000.0).collect(&:id)
        {model: 'lccp', ids: ids}
      end
    end

    def inc_searches(symbol)
      tag = self.by_symbol(symbol).first
      tag.inc :searches, 1 if tag
    end

    def update_matches
      self.all.map { |e|
        e.matches = self.send(e.symbol)[:ids].count
        e.save!
      }
      puts 'update matches Done!'
    end

    def import
      data = %w[
        all_lccp|lccp|理财产品|查看所有在售理财产品
        all_trust|trust|信托产品|查看所有在售信托产品
        all_bond|bond|最新国债|查看最新国债信息
        bb_lccp|lccp|保本理财产品|查看所有保本理财产品
        y1_trust|trust|一年信托|查看所有投资期为一年的信托产品
        w100_trust|trust|100万信托|查看所有100万的信托
        base_trust|trust|基建类信托|查看所有基础设施类信托
        big_bank_lccp|lccp|大银行理财产品|查看所有中行、建行、农行、工行、交行、招行、邮政储蓄的理财产品
        high_rate_saving|saving|定期最高银行|查看所有一年期定存利息最高的银行
        gt5_lccp|lccp|收益>5%理财|查看所有收益大于5%的理财产品
        gt10_trust|trust|收益>10%信托|查看所有收益大于10%的信托产品
        top10_trust|trust|TOP10信托公司|查看所有排名前10的信托公司的产品
        y2_trust|trust|2年信托|查看所有期限为2年的信托
        w300_trust|trust|300万信托|查看所有300万的信托
        lt100w_trust|trust|小于100万信托|查看所有小于100万起购金额的信托
        m3_lccp|lccp|3个月理财产品|查看所有期限小于3个月的理财产品
        w5_lccp|lccp|5万理财产品|查看所有5万元起购的理财产品
      ]

      data.each do |e|
        array = e.split("|")
        tag   = find_or_create_by symbol: array[0], category: array[1].to_s
        tag.update_attributes! name: array[2], description: array[3]
      end
      log("import tag successfully")
    end
  end
end
