# = MySQLのFULLTEXT INDEXをサポート
# = examples
# add_index :users, :profile, :fulltext => true
# add_index :users, :profile, :fulltext => :ngram
# add_index :users,  [:profile,:name], :fulltext => "NO NORMALIZE, NGRAM"
#
# ==インデックスタイプの指定
# + 単語(mecab)インデックスを作成する場合
#  指定無し
#  => FULLTEXT INDEX (text)
# + NGRAMインデックスを作成する場合
#  USING NGRAMを指定
#  => FULLTEXT INDEX USING NGRAM (text)
# + DELIMITED(空白で区切られた文字列単位)インデックスを作成する場合
#  USING DELIMITEDを指定
#  => FULLTEXT INDEX USING DELIMITED (text)
# + MySQLの素のfulltext indexを作成する(sennaインデックスを使用しない)場合
# USING NO SENNAを指定
# => FULLTEXT INDEX USING NO SENNA (text)
# == 正規化機能の使用/不使用
# デフォルトでは正規化機能が有効になります。無効化するためには、USING NO NORMALIZEを指定します。
# + (例) 正規化なしでNGRAMインデックスを作成する場合
# NO NORMALIZEは正規化無し 
# FULLTEXT INDEX USING NGRAM, NO NORMALIZE (text)
# + マルチセクション機能の使用/不使用(tritonn-1.0.4より)
# (例) NGRAMインデックスを指定しつつマルチセクション機能を利用する場合
# FULLTEXT INDEX USING NGRAM, SECTIONALIZE (text, text2)
# 
# CREATE FULLTEXT INDEX fulltext_index_articles USING NGRAM ON articles(body);

module ActiveRecord
  module ConnectionAdapters
    class IndexDefinition
      attr_accessor :fulltext
    end
    class MysqlAdapter < AbstractAdapter
      def indexes(table_name, name = nil)#:nodoc:
        indexes = []
        current_index = nil
        execute("SHOW KEYS FROM #{table_name}", name).each do |row|
          if current_index != row[2]
            next if row[2] == "PRIMARY" # skip the primary key
            current_index = row[2]
            indexes << IndexDefinition.new(row[0], row[2], row[1] == "0", [])
            index_type, index_using = row[10].split(/,/,2)
            indexes.last.fulltext = index_using || true if index_type=='FULLTEXT'
          end
          indexes.last.columns << row[4]
        end
        indexes
      end

      def add_index(table_name, column_name, options = {})
        column_names = Array(column_name)
        #index_name   = index_name(table_name, :column => column_names.first)
        index_name   = index_name(table_name, :column => column_names.join("_"))

        if Hash === options # legacy support, since this param was a string
          index_type = "UNIQUE" if options[:unique]
          index_type = "FULLTEXT" if options[:fulltext]
          index_using = "USING #{options[:fulltext].to_s}" if options[:fulltext].is_a?(String) || options[:fulltext].is_a?(Symbol)
          index_name = options[:name] || index_name
        else
          index_type = options
        end
        quoted_column_names = column_names.map { |e| quote_column_name(e) }.join(", ")
        execute "CREATE #{index_type} INDEX  #{quote_column_name(index_name)} #{index_using} ON #{table_name} (#{quoted_column_names})"
      end

      # テーブルのオプションを取得
      def table_options(table_name)
        options = nil
        execute("SHOW TABLE STATUS").each do |row|
          if row[0]==table_name
            options = []
            options << "TYPE='#{row[1]}'"
            options = options.join(',')
#Collation;
          end
        end
        options
      end
    end
  end

  class SchemaDumper
    private
      def table(table, stream)
        columns = @connection.columns(table)
        begin
          tbl = StringIO.new

          if @connection.respond_to?(:pk_and_sequence_for)
            pk, pk_seq = @connection.pk_and_sequence_for(table)
          end
          pk ||= 'id'

          tbl.print "  create_table #{table.inspect}"
          if columns.detect { |c| c.name == pk }
            if pk != 'id'
              tbl.print %Q(, :primary_key => "#{pk}")
            end
          else
            tbl.print ", :id => false"
          end
          tbl.print ", :force => true"
          tbl.print ", :options => #{@connection.table_options(table).inspect}" if @connection.respond_to? :table_options
          tbl.puts " do |t|"

          columns.each do |column|
            raise StandardError, "Unknown type '#{column.sql_type}' for column '#{column.name}'" if @types[column.type].nil?
            next if column.name == pk
            tbl.print "    t.column #{column.name.inspect}, #{column.type.inspect}"
            tbl.print ", :limit => #{column.limit.inspect}" if column.limit != @types[column.type][:limit]
            tbl.print ", :default => #{column.default.inspect}" if !column.default.nil?
            tbl.print ", :null => false" if !column.null
            tbl.puts
          end

          tbl.puts "  end"
          tbl.puts

          indexes(table, tbl)

          tbl.rewind
          stream.print tbl.read
        rescue => e
          stream.puts "# Could not dump table #{table.inspect} because of following #{e.class}"
          stream.puts "#   #{e.message}"
          stream.puts
        end

        stream
      end

      def indexes(table, stream)
        indexes = @connection.indexes(table)
        indexes.each do |index|
          stream.print "  add_index #{index.table.inspect}, #{index.columns.inspect}, :name => #{index.name.inspect}"
          stream.print ", :unique => true" if index.unique
          stream.print ", :fulltext => #{index.fulltext.inspect}" if index.fulltext
          stream.puts
        end
        stream.puts unless indexes.empty?
      end
  end
end
