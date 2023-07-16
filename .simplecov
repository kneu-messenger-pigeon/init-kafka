require 'simplecov'
require 'simplecov-cobertura'

SimpleCov.start do
  add_filter ".git/"
  add_filter "test/"
end

SimpleCov.formatter = SimpleCov::Formatter::CoberturaFormatter

