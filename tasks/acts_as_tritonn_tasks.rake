# desc "Explaining what the task does"
# task :acts_as_tritonn do
#   # Task goes here
# end
namespace :test do
  namespace :plugin do
    Rake::TestTask.new(:tritonn => :environment) do |t|
      t.libs << "test"

      t.pattern = File.dirname(__FILE__) + '/../test/*_test.rb'
      t.verbose = true
    end
  end
end
