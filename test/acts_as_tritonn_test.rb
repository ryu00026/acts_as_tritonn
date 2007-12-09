require File.dirname(__FILE__) + '/test_helper'
class ActsAsTritonnTest < Test::Unit::TestCase
  fixtures :test_users ,:test_comments
  
  def test_find_fulltext_fullname
    assert_equal(2, TestUser.find_fulltext(:fullname => "山田").size)
  end

  def test_find_fulltext_and_fullname
    assert_equal(1, TestUser.find_fulltext({:fullname => "山田 太郎"}).size)
  end

  def test_find_fulltext_or_fullname
    assert_equal(4, TestUser.find_fulltext({:fullname => ["山田", "一郎"]}).size)
  end
  
  def test_find_fulltext_with_conditions
    assert_equal(2, TestUser.find_fulltext({:fullname => "山田"}, :conditions => ["description LIKE ?","%京都%"]).size)    
  end
  
  def test_find_fulltext_two_cols_and_conjunction
    assert_equal(1, TestUser.find_fulltext({:fullname => "山田", :description => "東京" }).size)    
  end

  def test_find_fulltext_two_cols_or_conjunction
    assert_equal(3, TestUser.find_fulltext({:fullname => "山田", :description => "北京" }, :all => true).size)    
  end
  
  def test_find_fulltext_with_limit_and_order
    results = TestUser.find_fulltext({:fullname => ["山田", "一郎"]}, :limit => 1, :order => "id")
    assert_equal(1, results.size)
    assert_equal(1, results[0].id)
  end
  
  def test_find_fulltext_include
    results = TestUser.find_fulltext({:fullname => "山田", :comment => "東京"}, :include => :test_comments)
    assert_equal(2, results.size)
  end
  
  def test_find_fulltext_include_with_ambiguous_and_conjunction
    results = TestUser.find_fulltext({:fullname => "山田", :comment => "東京",  :"test_comments.description" => "東京"}, :include => :test_comments)
    assert_equal(1, results.size)    
  end
  def test_find_fulltext_include_with_ambiguous_or_conjunction
    results = TestUser.find_fulltext({:fullname => "山田", :comment => "東京",  :"test_comments.description" => "東京"}, :all => true, :include => :test_comments)
    puts results.size.to_s
    #assert_equal(3, results.size)    
  end

  
end
