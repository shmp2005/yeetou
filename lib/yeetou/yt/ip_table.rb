# -*- coding: utf-8 -*-
class Yt::IpTable
  include Yt::Abstract

  field :full_start_ip, type: String
  field :start_ip, type: String
  field :full_end_ip, type: String
  field :end_ip, type: String
  field :province, type: String
  field :city, type: String
  field :memo, type: String

  index({full_start_ip: 1, full_end_ip: 1}, {name: 'full_start_end_ip_index'})
  scope :search_by, lambda { |ip| lte(full_start_ip: normalize(ip)).gte(full_end_ip: normalize(ip)) }

  class << self
    def import(path="/d/ip.txt")

      unless File.exist?(path)
        log("无效的ip table路径. #{path}")
        return
      end
      log("清空旧有的ip数据库")
      self.delete_all

      ip = 0
      File.open(path) do |f|
        f.lines.each do |line|
          fs=line.split(",").map { |ele| ele.gsub("/|#VALUE!", "").strip }
          if fs.length == 5
            ip += 1
            create!(start_ip:      fs[0],
                    end_ip:        fs[1],
                    full_start_ip: normalize(fs[0]),
                    full_end_ip:   normalize(fs[1]),
                    province:      fs[2],
                    city:          fs[3],
                    memo:          fs[4])
            log("#{ip} => #{line}")
          else
            log("Warning=>#{line}")
          end
        end
      end
      log("导入结束。 (#{ip}) ")
    end

    #范式化：001.002.003.004
    def normalize(ip)
      array = ip.split(".")
      if array.length == 4
        array.map { |e| e.rjust(3, '0') }.join(".")
      else
        ip
      end
    end
  end
end
