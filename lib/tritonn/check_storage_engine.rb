# MyISAMじゃないとadd indexが実行されない
# = examples
#  def self.up
#    if ActiveRecord::Base.connection.respond_to?(:each_slaves)
#      ActiveRecord::Base.connection.each_slaves do |connection|
#        if support_fulltext?(connection, :fulltext_tables)
#          connection.add_index :fulltext_tables, :col, :fulltext => :ngram
#        end
#     end
#   end
module ::ActiveRecord # :nodoc:
  class Migration # :nodoc:
    def self.support_fulltext?(connection, table_name)
      connection.execute("show table status where name = '#{table_name}'").fetch_hash['Engine'] == "MyISAM"
    end
  end
end

