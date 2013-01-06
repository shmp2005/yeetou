#require "yeetou/fund/abstract"
Dir.glob("fund/**/*.rb").sort.map { |e| require e }
