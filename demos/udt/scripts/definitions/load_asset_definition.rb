if ARGV.length != 2
  raise "Not enough arguments!"
end


asset_definition = CKB::CellField.new(CKB::Source::DEP, 1, CKB::CellField::DATA)

eval("#{asset_definition}(#{ARGV})")
