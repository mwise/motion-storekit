guard 'motion' do
  watch(%r{^spec/.+_spec\.rb$})

  # RubyMotion gem example
  watch(%r{^lib/(.+)\.rb$})     { |m| "spec/#{m[1]}_spec.rb" }
end
