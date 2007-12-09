
module Tritonn #:nodoc:
  #
  # Example:
  #
  #   class Article < ActiveRecord::Base
  #     acts_as_tritonn
  #   end
  #
  # 全文検索機能を利用したいモデルに acts_as_tritonnを記述すると，Sennaを利用した全文検索が利用できます．
  # 全文検索クエリを簡単に使うことを目的としているため、細かくSenna演算子をつかったり、適合率でソートはできません。
  #
  module ActsAsTritonn
    def self.included(base)
      base.extend ClassMethods
    end

    module ClassMethods
      def acts_as_tritonn(options = {})
        return if self.included_modules.include?(Tritonn::ActsAsTritonn::InstanceMethods)
        send :include, Tritonn::ActsAsTritonn::InstanceMethods
      end
    end

    module InstanceMethods
      def self.included(base)
        base.extend SingletonMethods
      end
      module SingletonMethods
        # Example:
        # ==普通の検索
        # Model.find_fulltext({:col1 => "hoge"})
        #   => SELECT * FROM models WHERE MATCH(col1) AGAINST('hoge' IN BOOLEAN MODE);
        # == AND検索
        # Model.find_fulltext({:col1 => ["hoge foo"]})
        #   => SELECT * FROM models WHERE MATCH(col1) AGAINST('+hoge +foo' IN BOOLEAN MODE);
        # == OR検索
        # Model.find_fulltext({:col1 => ["hoge foo"]})
        #   => SELECT * FROM models WHERE MATCH(col1) AGAINST('+hoge +foo' IN BOOLEAN MODE);
        
        # count(*) as count_all        
        def count_fulltext(query, options={})
          options = fulltext(query, options)
          count = count(options)
          return count
        end
        
        def find_fulltext(query, options={})
          options = fulltext(query, options)
          results = find(:all, options)
          return results
        end
        
        private
        # 全文検索クエリ生成
        def fulltext(query, options={})
          raise ArgumentError, "wrong argument class" unless query.is_a? Hash
          conditions = []
          query.each_pair do |column, string|            
            str = ""
            if string.is_a? String
              # ANDか通常の検索
              ary = string.split(/[#{ActiveSupport::Multibyte::Handlers::UTF8Handler.codepoints_to_pattern(ActiveSupport::Multibyte::Handlers::UTF8Handler::UNICODE_WHITESPACE)}]+/)
              ary.each do |s| str << " +#{s}" end
              string = str
            elsif string.is_a? Array
              # OR検索
              string.each do |s| str << " #{s}" end
              string = str
            end
            conditions << %|MATCH(#{column.to_s}) AGAINST ("#{string}" IN BOOLEAN MODE)|
          end
          conjunction = options.delete(:all) ? ' OR ' : ' AND '
          if options[:conditions]
            if options[:conditions].is_a?(String)
              options[:conditions] = "(#{options[:conditions]}) AND (#{conditions.join(conjunction)})"
            elsif options[:conditions].is_a?(Array)
              options[:conditions][0] = "(#{options[:conditions].first}) AND (#{conditions.join(conjunction)})"
            end
          else
            options[:conditions] = conditions.join(conjunction)
          end
          #puts options.to_yaml
          return options
        end
        
        # TODO 
        # これを実装するとSennaでは使えなくなる・・・・
        #kwic(
        # 文書,
        # 切り出す文書の最大バイト数,
        # 切り出す文書の最大個数,  
        # htmlエンコーディングの有無,
        # snippetの開始タグ,
        # snippetの終了タグ, 
        # 単語1,
        # 単語1の前につけられるタグ,
        # 単語1の後につけられるタグ, 
        # 単語2,
        # 単語2の前につけられるタグ,
        # 単語2の後につけられるタグ, ...);        
        def kwic(query, kwic_options)
          #options = {}
          #snippet_options = snippet_options.is_a?(Hash) ? snippet_options.reverse_merge(options) : options
          #%|KWIC() as #{kwic_options[:label]}|
        end
      end
    end
  end
end
