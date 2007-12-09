ActiveRecord::Schema.define(:version => 0) do
  create_table :test_users, :options => "ENGINE=MyISAM DEFAULT CHARSET=utf8" , :force => true do |t|
    t.column :fullname, :string
    t.column :description, :text
  end
  add_index :test_users,  [:fullname], :fulltext => "NGRAM"
  add_index :test_users,  [:description], :fulltext => "NGRAM"


  create_table :test_comments, :options => "ENGINE=MyISAM DEFAULT CHARSET=utf8", :force => true do |t|
    t.column :test_user_id, :integer
    t.column :comment, :text
    t.column :description, :text    
  end
  add_index :test_comments,  [:comment], :fulltext => "NGRAM"
  add_index :test_comments,  [:description], :fulltext => "NGRAM"

end
